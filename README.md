# 河农随心充（hnd-charge-app）

面向河南农业大学龙子湖校区的充电桩状态查询 Android 应用，使用 Flutter 开发。用于出发前查看已收录设备的可用插口，并通过位置示意图寻找设备。

> 开发说明：本项目主要使用 GPT 编写代码。

当前安装包版本为 **v1.0.0**，已完成长期签名核验及维护者真机检查，项目仍在持续完善。应用并非学校或充电平台的官方产品，仅提供状态查询，不提供支付、预约或启动充电功能。

## 下载与安装

**[前往 Releases 页面下载 APK](https://github.com/saturdayxql/hnd-charge-app/releases)** · [v1.0.0 发布页](https://github.com/saturdayxql/hnd-charge-app/releases/tag/v1.0.0)

| 项目 | v1.0.0 安装包信息 |
|---|---|
| 应用名称 | 河农随心充 |
| 显示版本 / 内部版本号 | 1.0.0 / 2 |
| 系统与架构 | Android 7.0 及以上（API 24+）、arm64-v8a |
| APK 文件大小 | 7,487,554 字节，约 7.49 MB |
| 签名与检查 | 使用长期密钥签名，已核对证书指纹，并由维护者完成本次 release 包的真机检查 |

下载和安装步骤：

1. 点击上方链接进入 **Releases（发布）** 页面，打开需要的版本，例如 **河农随心充 v1.0.0**。
2. 展开版本下方的 **Assets（资源）**，下载以 `.apk` 结尾的安装包。v1.0.0 的文件名为 `henong-charge-v1.0.0-arm64-v8a.apk`；后续请以发布页实际附件为准。
3. 可以直接用手机下载，也可以在电脑下载后传到手机。下载完成后，在手机上打开 APK 文件。
4. 按 Android 安装提示操作；若系统要求授权，仅允许本次使用的浏览器或文件管理器安装应用，安装结束后可按需撤销该来源授权。
5. 安装完成后，打开 **河农随心充**。

`Assets` 中的 APK 用于手机安装；GitHub 自动提供的 `Source code (zip)` 和 `Source code (tar.gz)` 是源码压缩包，不能直接作为 Android 应用安装。同页的 `SHA256SUMS.txt` 可用于核对 APK 文件完整性。

此安装包仅适用于 arm64-v8a，不适用于仅支持 32 位 ARM 或 x86 的设备。安装时 Android 会解压原生库，因此安装后的空间占用会大于 APK 文件大小。

v1.0.0 对应的软件源码提交为 [`9affbec`](https://github.com/saturdayxql/hnd-charge-app/tree/9affbecfee71da7cc74564715153b519cc796912)，许可见本仓库的 [LICENSE](LICENSE)。

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

测试使用模拟查询结果，不需要访问真实充电平台。2026-11-14 对当时源码副本的验证结果为：`dart analyze` 无问题，33 项串行离线测试全部通过。v1.0.0 安装包另已完成签名、包名、版本及架构核验，并由维护者在真机上检查。历史测试记录不代替后续修改后的验证，也不代表所有手机上的兼容性测试。

### 构建开发安装包

```text
flutter build apk --debug
```

输出通常位于 `build/app/outputs/flutter-apk/app-debug.apk`。APK 不纳入源码提交；供用户安装的 release APK 通过上方 Releases 页面下载。

当前工程版本为 `1.0.0+2`，应用名称为“河农随心充”，Android 包名为 `io.github.saturdayxql.henongcharge`。release 构建使用专用长期密钥签名；构建前需在本机终端加载签名密码。缺少签名输入时会阻止 release 构建，不会自动回退到 debug 签名。

启动图标由 GPT 生成，原图保存在 `artwork/henong-charge-icon.png`，供后续设计维护使用；该目录没有加入 Flutter 运行时素材清单。Android 工程已提供不同密度的启动图标和自适应图标资源，本次 release 包的图标显示效果已由维护者在真机上检查。

为减小直接下载的 APK，release 构建会压缩打包原生库，安装时由 Android 解压；因此 APK 文件大小不等于安装后的空间占用。debug 打包方式保持不变。

### 正式签名准备

复制 `android/key.properties.example` 为本地 `android/key.properties`，填写私有 PKCS12 密钥库的路径及别名。Windows 路径建议使用 `/` 分隔。该本地文件已被 Git 忽略，不存放密码；密钥库也应保存在工程外并独立备份。

签名密码通过当前构建终端的 `HENONG_SIGNING_PASSWORD` 环境变量传入，PKCS12 私钥使用相同密码。不要把密码写进源码、示例配置或命令参数。普通 debug 开发不需要这套 release 密钥。

长期密钥需由维护者在本机交互创建并核对证书；配置文件存在不等于密钥已经生成。release 构建前会检查本地配置、密钥文件、别名和会话密码，缺失时明确报错。

## 源码结构

| 路径 | 作用 |
|---|---|
| `lib/station_config.dart` | 区域、设备编号与展示顺序 |
| `lib/station_service.dart` | 平台请求、响应校验与插口解析 |
| `lib/area_controller.dart` | 并发队列、批次隔离、进度与汇总 |
| `lib/main.dart` | 应用主题、区域切换及列表/地图页面框架 |
| `lib/area_bar.dart` | 区域标签栏与大字号布局 |
| `lib/station_overview.dart` | 整桩速览及卡片跳转 |
| `lib/summary_header.dart` | 可用插口汇总、查询进度和接收时间 |
| `lib/station_card.dart` | 桩卡片、插口状态及旧数据提示 |
| `lib/status_style.dart` | 状态配色、文字层级和布局测量 |
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

本项目的软件源码（包括 v1.0.0 对应源码）采用 **GNU General Public License version 3（GPL v3）**，完整许可文本见 [LICENSE](LICENSE)。

你可以在该许可条件下使用、修改和再分发，包括商业用途；分发受其约束的程序及修改版时，需要保留适用的版权与许可声明，并履行相应的源码提供等义务，具体以完整许可条款为准。

第三方组件、参考内容和素材保留其原有版权及许可声明；本项目的许可说明不替代或消除这些要求。软件按许可条款以现状提供，不附带保证。

## 问题反馈

反馈时请说明区域、桩号、查询时间、操作步骤、错误提示、手机型号和 Android 版本。位置图问题请附方向与编号对应关系；截图请遮挡无关个人信息，不要提交密码、访问凭据或支付订单。
