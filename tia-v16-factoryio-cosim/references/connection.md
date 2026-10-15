# 连接与排错

## 普通 PLCSIM V16 主路径

依据 [Factory I/O 官方教程](https://docs.factoryio.com/tutorials/siemens/setting-up-s7-plcsim-v13/)：需要支持 Siemens 驱动的 Siemens Edition 或 Ultimate Edition，以及 TIA/PLCSIM V16。官方 V15 的 S7-1200、S7-1500 模板兼容 V16。在官方页面按实际 CPU 家族选择模板；不随 skill 重新分发 Siemens 工程或授权软件。

1. 用 V16 打开模板，在任务工作区另存为仿真工程；保存原模板。使用已有工程时先确认模板通信内容是否存在，必要时在模板副本中迁入用户逻辑，不能删除或覆写 OB1 原有网络 1。
2. 编写逻辑并编译。启动仿真，下载界面选择 PN/IE 和 PLCSIM S7-1200/S7-1500，搜索并核实模拟目标，再下载。将 PLCSIM CPU 置 RUN。
3. Factory I/O 的 File > Driver Configuration 选择 Siemens S7-PLCSIM。Configuration 的 Model 匹配 CPU 与 V16；新版本界面可显示 S7-1200/S7-1500 (V14-19)。旧界面以实际可选项和该版本文档为准。
4. 配置并核对数字量/模拟量地址，连接后观察绿色状态。启动场景，验证 I 和 Q 双向传递；同一信号不要同时由 PLCSIM 表和 Factory I/O 写入。

## Advanced 分支

先辨明它确实是 S7-PLCSIM Advanced，而非普通 V16。按 [官方 Advanced V3 教程](https://docs.factoryio.com/tutorials/siemens/setting-up-s7-plcsim-advanced-V3/) 或其对应版本教程核对兼容 CPU、工程支持仿真选项和运行实例。驱动 Model 使用 Advanced 类型；默认实例名 `factoryio`，已有名称则核对驱动的 `drivers.siemens_s7plcsim.instance_name` 配置。[驱动手册](https://docs.factoryio.com/manual/drivers/s7-plcsim/)

不要因普通 PLCSIM 连接失败就安装 Advanced、NetToPLCSim 或改走以太网驱动；这会改变前提。用户要求该路线时先查它的版本文档。

## 定位故障

| 现象 | 优先获取的证据与处理 |
|---|---|
| 找不到驱动 | Factory I/O 产品版本、授权版本与驱动列表；诊断脚本不能证明授权 |
| PLCSIM 搜索不到 CPU | 模拟器是否启动、CPU 家族、实际 PG/PC 接口和下载搜索结果 |
| 驱动无法连接 | 模板来源、OB1 网络 1 是否保留并已下载、CPU RUN、驱动 Model |
| 连接但 I 不变化 | 场景运行状态、传感器实际值、映射方向与输入偏移、写入冲突 |
| Q 有值但执行器不动 | 输出映射/偏移、现场景是否使用该 tag、运行/暂停状态及手动覆盖 |
| 模拟量不合理 | WORD/DWORD 设置、TIA 数据类型、位解释与量程；先看原始值再修改算法 |
| 多工程或多实例 | 明确 PID、工程路径、CPU/实例名称，不反复盲目连接 |

一次更改一类配置并重新观察。不能以通用“开放 TCP 102、启用 PUT/GET、关闭优化 DB”解决所有普通 PLCSIM 问题；这些不是本路径的默认条件。
