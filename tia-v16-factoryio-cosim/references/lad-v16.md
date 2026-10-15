# V16 LAD 编辑

## 首选可验证的基线

确认当前文件为 V16 `.ap16` 工程或 `.zap16` 归档；V15 官方模板升级到 V16 时使用副本。更高版本工程不可通过改扩展名降级。保留需求中的 CPU 和固件，未确认硬件目录支持前不替换型号。

从实际 V16 导出中学习结构，或在 GUI 建立一个所需指令的小 LAD 样板再导出。不要将 V18/V19 的 FlgNet、Interface 命名空间或第三方脚本直接用于 V16。可以参考本机 `PublicAPI\V16\Schemas`；创建时在本机发现 LADFBD_v4、Access_v4、InterfaceSections_v4 文件，但每次以实际导出为准。

## 代理执行顺序

1. 记录 PID、工程绝对路径、CPU、块路径和语言；保存可恢复副本，导出被改块/变量表及原 OB1，记录 SHA-256。
2. 从场景真实信号建立 I/O 表，校验方向和地址冲突。分离通信网络与控制网络，保留原 OB1 网络 1，并将新增 FB/FC 调用放在其后的合适位置。
3. 根据需求设计 LAD：使能和停止优先级、互锁、步进状态、沿触发、超时、复位和上电行为。不要擅自决定 Stop 是立即停止还是完成当前周期；场景需求不能确定时问用户。传感器触点极性来自实测，不能仅凭“急停”名称假定逻辑。
4. XML 修改保持当前 V16 结构、局部 UId 关系和显式声明。TON/计数器/FB 调用应取自相同 V16 的导出样板，正确关联实例 DB；禁止靠猜指令 XML 拼出梯形图。
5. 解析 XML、检查引用，然后导入授权的仿真副本，按依赖先类型/数据、后调用者。编译实际 PLC，查看错误和警告并修正；成功后保存。编译失败保留诊断，不下载。
6. 对比最终 OB1 与模板通信网络，确认未丢失；再进入仿真下载和闭环测试。

若没有可用 V16 写入工具，交付 LAD 网络清单、符号表和可人工建立的指令连接说明。SCL 文本不能当作 LAD 交付；未在 V16 导入编译的 XML 标为候选，不能标为可用工程。

## Openness 适配依据

使用本机 V16 `Siemens.Engineering.dll`，Windows PowerShell 5.1/.NET Framework 与安装匹配的进程架构。只读枚举脚本不 Attach；真正连接时先选定会话并遵循 Siemens 的 Openness 授权界面。修改用户组、安装组件或白名单均不属于日常写块操作。

本机 V16 XML API 文档已确认存在：

- `TiaPortal.GetProcesses()` 与 `TiaPortalProcess.ProjectPath`。
- `PlcBlock.Export(FileInfo, ExportOptions)`。
- `PlcBlockComposition.Import(FileInfo, ImportOptions)`。
- `Compiler.ICompilable.Compile()`。

这里不附未经实测的通用导入/下载脚本。实施时从当前安装的 `Siemens.Engineering.xml`、官方手册和真实导出核对服务对象、参数与返回值。现有 `tia-v18-lad-agent-harness` 仅作方法参考；本 skill 不调用其 V18 EXE 或包装器。

仿真 Stop/互锁测试只验证教学控制逻辑，不作为硬件安全功能认证。
