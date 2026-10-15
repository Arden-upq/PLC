# I/O 映射与验收

## 映射文件

使用 CSV 表头 `signal,plc_tag,kind,address,data_type,encoding`。`kind` 为 `sensor` 或 `actuator`：场景传感器写 PLC I，场景执行器读 PLC Q。地址统一使用 `%I0.0`、`%Q0.0`、`%IW100`、`%ID104` 等国际形式。使用中文信号名时保存为 UTF-8；脚本也接受 UTF-8 BOM。

从真实 Driver Configuration 和变量表录入，不能照搬例子。`assets/io-map-example.csv` 是数字量示例，不代表用户场景。实际工程应补充注释、单位、量程、正常极性及复位状态；额外 CSV 列会保留但不被当前检查器解释。

运行：

```powershell
python .\scripts\validate_io_map.py .\assets\io-map-example.csv
python .\scripts\validate_io_map.py .\work\io-map.csv --input-bytes 256 --output-bytes 256 --output .\work\io-validation.json
```

范围参数是“已核实可用 I/Q 区域的字节数”，示例 256 不是 CPU/驱动的默认容量。未知时省略；脚本会明确显示范围未核实。还需人工比较驱动各项 Offset/Count 与映射地址，不能把 CSV 通过当作这些设置已经正确。

检查器检测缺列/空表、方向、位地址和宽度、类型与编码不匹配、重复信号/符号、位级内存重叠及给定范围越界。仅支持 I/Q 的 Bool、Byte、Int、Word、DInt、DWord、Real；不处理 DB、M、结构数组或符号寻址。它不生成 Siemens tag XML，不替代 TIA 编译。

## 模拟量

依据 [S7-PLCSIM 驱动手册](https://docs.factoryio.com/manual/drivers/s7-plcsim/)核对 Numerical Data Type：

| 驱动格式 | 场景值 | TIA 类型 / CSV encoding |
|---|---|---|
| DWORD | 浮点 | Real / `real` |
| DWORD | 整数 | DInt 或 DWord / `integer` |
| WORD | 整数 | Int 或 Word / `integer` |
| WORD | 0–10 V 浮点 | Int 或 Word / `scaled_0_10v`，原始 0–27648 |
| WORD | −10–10 V 浮点 | Int / `scaled_bipolar_10v`，原始 −27648–27648 |

CSV 类型表达 PLC 解释，`WORD`/`DWORD` 驱动格式不等于必须用同名 PLC 类型。REAL 位模式不能简单按整数做数值转换。缩放以传感器的实际输出约定和工程量量程为准，不假定所有场景采用电压单位。Byte 仅用于已核实的整字节映射。

Bool 为 `digital`。脚本允许 DWORD 整数按工程选择有符号/无符号解释，但须另行验证边界；负数不能使用 Word/DWord 解释。模拟量行须与现场驱动 WORD/DWORD 设置一致。

## 验收顺序

先做一条可控输入和一条低影响的仿真输出：观察场景传感器改变、对应 I 值、LAD 路径、Q 值及执行器反应。PLC 逻辑输出测试优先于长期强制；任何临时监控表修改都要记录并清除，避免多写入者。

再按实际场景测试完整周期、Stop/Reset、重复启动、上电初态、超时和互锁。用需求预期对比实际结果；涉及运动方向时验证相互排斥输出不会同时有效。未要求的场景功能不额外扩展。

记录每项操作、期望、观察、通过/失败/未测试，以及工程/场景版本。清除临时覆盖后重新运行一次正常周期；报告保留的问题。
