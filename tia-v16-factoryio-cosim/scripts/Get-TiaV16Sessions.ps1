[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$EngineeringDll)
$ErrorActionPreference = 'Stop'
try {
    if (-not [Environment]::Is64BitProcess) { throw 'Run 64-bit Windows PowerShell 5.1.' }
    if ($PSVersionTable.PSEdition -eq 'Core') { throw 'Use Windows PowerShell 5.1, not PowerShell Core.' }
    $dllFile = Get-Item -LiteralPath $EngineeringDll
    $identity = [Reflection.AssemblyName]::GetAssemblyName($dllFile.FullName)
    if ($identity.Name -ne 'Siemens.Engineering' -or $identity.Version.Major -ne 16) {
        throw ('Expected Siemens.Engineering V16; found ' + $identity.FullName)
    }
    $assembly = [Reflection.Assembly]::LoadFrom($dllFile.FullName)
    $portalType = $assembly.GetType('Siemens.Engineering.TiaPortal', $true)
    $method = $portalType.GetMethod('GetProcesses', [Reflection.BindingFlags]'Public,Static')
    $sessions = @($method.Invoke($null, $null) | ForEach-Object {
        [pscustomobject]@{
            processId = $_.Id
            executablePath = $(if ($_.Path) {$_.Path.FullName} else {$null})
            projectPath = $(if ($_.ProjectPath) {$_.ProjectPath.FullName} else {$null})
            mode = [string]$_.Mode
        }
    })
    [pscustomobject]@{success=$true; mode='read_only_no_attach'; sessions=$sessions} | ConvertTo-Json -Depth 5
} catch {
    $errorMessage = $_.Exception.Message
    if ($_.Exception.InnerException) { $errorMessage += ' | ' + $_.Exception.InnerException.Message }
    [pscustomobject]@{success=$false; mode='read_only_no_attach'; error=$errorMessage} | ConvertTo-Json
    exit 1
}
