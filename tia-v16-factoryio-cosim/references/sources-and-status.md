# 来源与验证状态

资料核对日期：2026-10-13。版本变化时重新核对对应产品文档。

## 主要来源

- [Factory I/O：普通 S7-PLCSIM V13–19 设置](https://docs.factoryio.com/tutorials/siemens/setting-up-s7-plcsim-v13/)：V15 模板兼容 V16、通信网络保护和连接步骤。
- [Factory I/O：Siemens S7-PLCSIM 驱动](https://docs.factoryio.com/manual/drivers/s7-plcsim/)：映射方向、数字量/模拟量格式、Advanced 实例名称。
- [Factory I/O：Advanced V3 设置](https://docs.factoryio.com/tutorials/siemens/setting-up-s7-plcsim-advanced-V3/)：仅用于匹配该版本的 Advanced 路线。
- [Siemens V16 Openness 手册](https://support.industry.siemens.com/cs/attachments/109773802/TIAPortalOpenness_en-US.pdf)：版本程序集与 API；实施时应以本机安装的 V16 API 文档和真实导出为准。
- [GitHub V16 电梯工程](https://github.com/hugotallys/factoryio-elevator)：LAD 场景参考，未复制其逻辑。
- [GitHub tia-openness-api](https://github.com/rraxge/Agent_skill_tia_openness_api)：相邻的较高版本 Openness 参考，不能据此宣称 V16 可用。

## 能力边界

本 skill 提供环境探测、V16 只读会话枚举、I/O 映射离线校验、LAD 编辑指导和联合仿真排错流程。文档依据不等于现场验证；实际导入、编译、下载、CPU RUN、驱动连接和闭环测试必须在用户指定的离线仿真环境中分别记录证据。

不分发 TIA Portal、Factory I/O、许可证、通信 DLL 或官方模板工程。通过官方链接取得所需模板；源于第三方工程的后续复用先检查其许可证。
