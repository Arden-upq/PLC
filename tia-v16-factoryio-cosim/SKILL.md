---
name: tia-v16-factoryio-cosim
description: 配置、编程和排查 Siemens 博图 TIA Portal V16、S7-PLCSIM V16 与 Factory I/O 联合仿真；支持 LAD 工作流、模板保护和 I/O 映射校验。用于离线仿真工程，不用于真实 PLC 调试或安全程序。
---

# V16 与 Factory I/O 联合仿真

交付可复现的仿真工程、I/O 表和联调证据。默认保留 LAD；用户明确要求其他语言时遵循其选择。本 skill 是代理操作指引与离线校验工具，不是 Factory I/O 通信驱动或一键自动化桥接器。

## 先确定实际环境

运行以下命令（路径相对本 skill 目录；诊断输出写到任务工作区）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Get-CosimEnvironment.ps1 -OutputJson .\work\environment.json
```

记录 TIA/PLCSIM 版本、Factory I/O 产品版本与授权驱动、CPU 家族、工程路径、场景和现有映射。脚本输出 `not_detected` 表示未发现证据，不表示软件一定未安装；绿色驱动状态与软件许可证须从实际应用核对。Unity 可执行文件版本不能当作 Factory I/O 产品版本。

如果需要确定当前 TIA 会话，可执行只读枚举：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Get-TiaV16Sessions.ps1 -EngineeringDll 'C:\Program Files\Siemens\Automation\Portal V16\PublicAPI\V16\Siemens.Engineering.dll'
```

`-ExecutionPolicy Bypass` 仅作用于本次子进程，不能持久修改系统策略；若组织策略禁止则报告限制。会话枚举为空不证明 TIA 未运行，核对进程、会话隔离和 Openness 用户组。

多会话时用实际 PID 和工程路径选择目标，不能默认取第一个。创建 skill 的授权不包含编辑现有 PLC 工程。后续用户要求“完成联合仿真”时，可在其指定的仿真工程范围内推进，不要重复索要已有授权；下载前核实目标是 PLCSIM。

## 按任务选择工作流

- 建立通信或排查连接：读 [连接与排错](references/connection.md)。默认采用普通 S7-PLCSIM V16；Advanced 是另一路径，不能混用配置。
- 编写或修改 LAD、变量表、DB：读 [V16 LAD 编辑](references/lad-v16.md)。先保存仿真副本和当前导出，保护模板 OB1 网络 1。
- 规划数字量或模拟量地址：读 [I/O 映射与验收](references/io-and-tests.md)，再运行 CSV 校验脚本。
- 核对支持边界或选择资料：读 [来源与验证状态](references/sources-and-status.md)。现成 GitHub 工程用于参考，不能代替官方通信模板和本机实测。

GUI 操作仅在实际工具支持该应用时执行，并遵守当前 computer-use 技能；没有 native Windows 控制能力时，不宣称已点击应用。继续准备映射、LAD 网络说明和排错结论，把必须手动执行的步骤明确交给用户。Openness 不可用时可走 GUI；不能因此静默改用其他版本或语言。

## 联调结束的证据

分别报告：离线校验、V16 编译、仿真下载、CPU RUN、驱动连接、传感器变化进入 I、PLC 输出经 Q 驱动场景、停止/复位与重启行为。只有实际观察过的项才标为通过；编译成功或绿色连接本身都不证明闭环正确。

保留工程/场景标识、最终映射、编译结果和复现步骤。未完成的项写明具体阻碍及下一步，不以脚本通过替代联合仿真通过。不自动发布 GitHub、不更改系统防火墙或用户组、不下载到物理设备。
