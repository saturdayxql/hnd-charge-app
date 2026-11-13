# 校园充电桩（hnd-charge-app）

面向河南农业大学龙子湖校区的充电桩状态查询 Android 应用，使用 Flutter 开发。用于出发前查看已收录设备的可用插口，并通过位置示意图寻找设备。

> 开发说明：本项目主要使用 GPT 编写代码。

当前为开发原型，并非学校或充电平台的官方应用。仅提供状态查询，不提供支付、预约或启动充电功能。

## 当前功能

- 按区域浏览全部已收录设备，每台设备查询完成后立即更新。
- 使用最多 5 个并发请求动态补位；查询过程中可以切换区域。
- 区分可用、充电中、不可用和未知状态，显示平台返回的插口编号，包括合法的 0 号口。
- 单台查询失败时显示错误；同区域刷新保留上次成功结果，并明确标记为旧数据。
- 提供创新大厦旁的位置示意图，点击桩号查看详情；地图与列表共用查询结果。

| 区域 | 已收录设备数 | 位置图 |
|---|---:|---|
| 创新大厦旁 | 20 | 已提供相对位置示意图 |
| 兰亭 | 12 | 待补充 |
| 二餐 | 6 | 待补充 |
| 行政楼 | 2 | 待补充 |
| 合计 | 40 |  |

## 状态说明

| 单插口颜色 | 含义 |
|---|---|
| 绿色 | 可用 |
| 红色 | 充电中 |
| 橙色 | 不可用 |
| 灰色 | 未知 |

位置图中的颜色表示整台设备的汇总状态：绿为有已知空口，红为无空口且插口状态均已知，橙为无已知空口且含未知状态，灰为等待、加载或查询失败。整桩红色不表示每个插口都正在充电。

## 开发与运行

### 环境

当前开发环境使用 Flutter **3.47.9 stable**、Dart **3.13.7**。Android 构建需要配置 Android SDK 和可用的 Java 环境；现有开发记录使用 Android Studio 随附的 JBR 25，Java/Kotlin 代码目标为 17。

工程中的 Gradle Wrapper 配置为 9.3.1，Android Gradle Plugin 为 9.1.0，Kotlin Android 插件为 2.4.0。其他工具版本组合尚未验证，开始前请检查本机环境，不要直接照搬他人的 SDK 路径。

在项目根目录执行：

```text
flutter --version
flutter doctor -v
flutter pub get
flutter devices
flutter run -d YOUR_DEVICE_ID
```

将 `YOUR_DEVICE_ID` 替换为 `flutter devices` 列出的目标 Android 设备标识。首次连接真机时，需要在手机上开启并授权 USB 调试。

Android 构建以 Flutter 命令为入口。当前忽略规则不纳入 `android/gradlew`、`android/gradlew.bat` 和 Wrapper JAR；Flutter 工具会在需要时从 SDK 缓存补齐缺失文件。克隆后不应直接假定这些脚本存在。尚未完成全新克隆及全新电脑环境的构建验证。

### 分析与离线测试

```text
dart analyze
flutter test --no-pub --concurrency=1
```

测试使用模拟查询结果，不需要访问真实充电平台。2026-11-09 对当时源码副本的验证结果为：`dart analyze` 无问题，18 项离线测试全部通过。该记录不代替后续修改后的验证，也不代表现场状态核验或所有手机上的兼容性测试。

### 构建开发安装包

```text
flutter build apk --debug
```

输出通常位于 `build/app/outputs/flutter-apk/app-debug.apk`。APK 不纳入源码仓库；目前没有正式发布版下载入口。

当前工程版本为 `1.0.0+1`，Android 包名为 `com.example.hnd_charge_app`。release 构建仍配置为 debug 签名，正式包名、应用名称、图标、长期签名及版本发布方式尚待确定。不能将现有 release 配置视为正式签名方案。

## 源码结构

| 路径 | 作用 |
|---|---|
| `lib/station_config.dart` | 区域、设备编号与展示顺序 |
| `lib/station_service.dart` | 平台请求、响应校验与插口解析 |
| `lib/area_controller.dart` | 并发队列、批次隔离、进度与汇总 |
| `lib/main.dart` | 区域选择、状态列表与插口卡片 |
| `lib/station_map.dart` | 创新大厦旁相对位置示意图 |
| `test/` | 配置、解析、并发、切换、地图及布局的离线测试 |
| `android/` | Android 原生工程与构建配置 |

## 已知局限

- 状态来自第三方平台，可能延迟、变化或查询失败；显示的接收时间不等于设备采集时间。
- 位置图仅表达现场相对关系，不是 GPS 导航或测绘成果。除创新大厦旁外，其他区域的位置图尚未补充。
- 切换区域会停止旧批次尚未发出的任务，并忽略旧结果；在途旧请求不会立即取消，新区域可能等待槽位释放。
- 没有自动轮询、自动重试、跨区域状态缓存或后台整点采集；切换区域后会重新查询。
- 当前网络实现面向 Android，尚未验证 iOS，也不能直接作为 Flutter Web 网络层使用。
- 本项目不控制第三方平台，接口可用性及平台使用条件需要另行核对。

## 参考与致谢

本项目开发过程中参考了 [AprDeci/HNDchargestation](https://github.com/AprDeci/HNDchargestation) 的充电状态查询实现思路，感谢原作者公开分享相关实现与设备信息。

- 兰亭、二餐（原项目称“二食堂”）和行政楼的设备编号及顺序参考原项目的 [`lib/app/areas.dart`](https://github.com/AprDeci/HNDchargestation/blob/master/lib/app/areas.dart)。
- 创新大厦旁的设备顺序与位置示意图依据项目维护者提供的现场清单及示意资料整理。
- 原项目采用 GNU GPL v3，详见其 [LICENSE](https://github.com/AprDeci/HNDchargestation/blob/master/LICENSE)。

## 本项目许可证

本项目许可证尚未确定，当前仓库用于开发与版本备份，尚未以选定的开源许可证发布。本节不是对第三方内容的重新授权；相关内容仍需遵守其实际适用的许可。

公开发布源码或分发 APK 前，需要根据实际复用范围确认许可要求，并补齐对应许可证及必要声明。

## 问题反馈

反馈时请说明区域、桩号、查询时间、操作步骤、错误提示、手机型号和 Android 版本。位置图问题请附方向与编号对应关系；截图请遮挡无关个人信息，不要提交密码、访问凭据或支付订单。
