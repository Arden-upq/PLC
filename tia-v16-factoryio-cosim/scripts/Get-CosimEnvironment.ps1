[CmdletBinding()]
param(
    [string]$TiaRoot,
    [string]$PlcsimExe,
    [string]$FactoryIoExe,
    [string]$OutputJson
)
$ErrorActionPreference = 'Stop'
# Read-only inventory; never attaches to an engineering project.
$warnings = [System.Collections.Generic.List[string]]::new()
function Get-BinaryEvidence([string]$Candidate) {
    if (-not $Candidate -or -not (Test-Path -LiteralPath $Candidate -PathType Leaf)) { return $null }
    $item = Get-Item -LiteralPath $Candidate
    [pscustomobject]@{
        path = $item.FullName
        fileVersion = $item.VersionInfo.FileVersion
        productVersion = $item.VersionInfo.ProductVersion
        productName = $item.VersionInfo.ProductName
    }
}
$apps = @(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'TIA Portal|STEP 7|PLCSIM|Factory I/O|Factory IO|Openness' } |
    Select-Object DisplayName, DisplayVersion, InstallLocation)
$running = @(Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -match 'Siemens.Automation.Portal|plcsim|s7.*sim|factory.?io' } |
    ForEach-Object {
        $processPath = $null
        try { $processPath = $_.Path } catch { $warnings.Add('Process path unavailable: ' + $_.Id) }
        [pscustomobject]@{name=$_.ProcessName; processId=$_.Id; path=$processPath}
    })
$roots = [System.Collections.Generic.List[string]]::new()
if ($TiaRoot) { $roots.Add($TiaRoot) }
foreach ($basePath in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if ($basePath) { $roots.Add((Join-Path $basePath 'Siemens\Automation\Portal V16')) }
}
foreach ($proc in $running) {
    if ($proc.name -eq 'Siemens.Automation.Portal' -and $proc.path) {
        $roots.Add((Split-Path (Split-Path $proc.path -Parent) -Parent))
    }
}
$dlls = @($roots | Select-Object -Unique | ForEach-Object {
    Get-BinaryEvidence (Join-Path $_ 'PublicAPI\V16\Siemens.Engineering.dll')
} | Where-Object { $null -ne $_ })
$simFiles = [System.Collections.Generic.List[object]]::new()
if ($PlcsimExe) {
    $explicitSim = Get-BinaryEvidence $PlcsimExe
    if ($explicitSim) { $simFiles.Add($explicitSim) } else { $warnings.Add('Explicit PLCSIM path not found.') }
}
foreach ($proc in $running) {
    if ($proc.name -match 'plcsim|s7.*sim') {
        $binary = Get-BinaryEvidence $proc.path
        if ($binary) { $simFiles.Add($binary) }
    }
}
$factoryFiles = [System.Collections.Generic.List[object]]::new()
if ($FactoryIoExe) {
    $explicitFactory = Get-BinaryEvidence $FactoryIoExe
    if ($explicitFactory) { $factoryFiles.Add($explicitFactory) } else { $warnings.Add('Explicit Factory I/O path not found.') }
}
foreach ($proc in $running) {
    if ($proc.name -match 'factory.?io') {
        $binary = Get-BinaryEvidence $proc.path
        if ($binary) { $factoryFiles.Add($binary) }
    }
}
$groups = @()
try {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $groups = @($identity.Groups | ForEach-Object {
        try { $_.Translate([System.Security.Principal.NTAccount]).Value } catch { $_.Value }
    } | Where-Object { $_ -match 'Siemens.*Openness' })
} catch { $warnings.Add('Could not inspect current token Openness group membership.') }
$simRegistered = @($apps | Where-Object { $_.DisplayName -match 'PLCSIM' })
$factoryRegistered = @($apps | Where-Object { $_.DisplayName -match 'Factory I/O|Factory IO' })
$report = [pscustomobject]@{
    collectedAt = [DateTimeOffset]::Now.ToString('o')
    probeMode = 'read_only_no_attach'
    registeredApplications = $apps
    runningProcesses = $running
    tiaV16Openness = [pscustomobject]@{
        status = $(if ($dlls.Count) {'detected'} else {'not_detected'})
        assemblies = $dlls
        tokenOpennessGroups = $groups
    }
    plcsim = [pscustomobject]@{
        status = $(if ($simRegistered.Count -or $simFiles.Count) {'detected'} else {'not_detected'})
        registrations = $simRegistered
        binaries = @($simFiles.ToArray())
        runtimeAndVersionVerified = $false
    }
    factoryio = [pscustomobject]@{
        status = $(if ($factoryRegistered.Count -or $factoryFiles.Count) {'detected'} else {'not_detected'})
        registrations = $factoryRegistered
        binaries = @($factoryFiles.ToArray())
        driverLicense = 'not_verified'
        productVersion = 'verify_in_application_unity_binary_version_may_differ'
    }
    limitations = @('Not-detected is not proof of absence; portable/stopped installations may be missed.',
        'No license, project, CPU RUN, connection, import, compile or closed-loop validation is performed.')
    warnings = @($warnings.ToArray())
}
$json = $report | ConvertTo-Json -Depth 8
if ($OutputJson) {
    $outputFile = [IO.Path]::GetFullPath($OutputJson)
    $null = New-Item -ItemType Directory -Path (Split-Path $outputFile -Parent) -Force
    [IO.File]::WriteAllText($outputFile, $json, [Text.UTF8Encoding]::new($false))
}
$json
