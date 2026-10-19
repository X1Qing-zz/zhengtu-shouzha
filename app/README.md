# 征途手札 · Zhengtu Shouzha · v0.3.0

> 记录「大世界（地球 Online）冒险生活」的移动端手札。
> 把日常写成一场冒险：日记、任务、账本、天气，以及一点恰到好处的谏言。

![App Icon](assets/branding/app_icon_1024.png)

## 这是什么

征途手札是一个 **本地优先** 的 Flutter 应用，覆盖 MVP 四件套：

- **手札**：一天一篇，自由文本 + 最多 9 张照片 + 心情 + 标题，自动按日期归档。
- **任务**：主线 / 支线、优先级、截止日期、完成时间戳；日历按「完成时间」聚合。
- **账本**：金额 + 固定分类 + 备注 + 时间；月度总览、分类占比、近 7 天节奏。
- **天气**：Open-Meteo 免费数据，支持当前定位或手动城市，当天缓存，生成出行建议。
- **日历**：点任意日期，聚合当天手札、完成的任务和开支。
- **谏言**：每日一句，可手动换一句。
- **冒险周报**：周切换、关键词、叙事、四格统计、任务/支出双柱状图、分类环形图、本周高光。
- **手札精灵**：4 条完全本地的规则建议，不依赖大模型或网络。
- **分享卡片**：一键生成 1088×1360 周报 PNG，调起系统分享面板。
- **备份与恢复**：把全部记录、设置和照片打包成 ZIP；支持系统分享、从文件恢复、应用内最近备份恢复。

所有记录默认只保存在设备上，不需要账号，也不会上传。

## 技术栈

| 层 | 选择 |
|---|---|
| 框架 | Flutter 3.47 / Dart 3.13 |
| 状态管理 | Provider + ChangeNotifier |
| 本地存储 | SQLite（sqflite），图片存应用文档目录 |
| 网络 | Open-Meteo（天气 / 城市搜索）、BigDataCloud（逆地理） |
| 定位 | geolocator |
| 图片 | image_picker |
| 分享 | share_plus（周报 PNG / 备份 ZIP） |
| 备份 | archive（ZIP）+ file_picker（选择备份） |
| 设置 | shared_preferences |
| 视觉 | 自定义暖纸/墨色主题、衬线中文标题、手绘天气图形 |

## 目录结构

```
lib/
  main.dart                 入口
  app.dart                  MaterialApp / 主题 / 本地化
  core/
    theme.dart              色板、字体、组件主题
    date_utils.dart         日期与连续记录
    formatters.dart         金额格式化
  data/
    models.dart             日记 / 任务 / 开销 / 天气模型
    database.dart           SQLite 建库
    repositories.dart       四个数据仓库
    weather_service.dart    Open-Meteo + 建议生成
    location_service.dart   定位与权限
    image_store.dart        图片落盘
    backup_service.dart     ZIP 备份导出 / 校验 / 恢复
    settings_store.dart     SharedPreferences
    quotes.dart             谏言库
  state/app_store.dart      单 Store，负责数据、天气、统计
  features/
    onboarding.dart         首次启动
    shell.dart              底部导航
    home/                   今日主页
    diary/                  手札列表与编辑器
    tasks/                  任务列表与编辑器
    ledger/                 账本与记账
    calendar/               日历聚合与当日详情
    weather/                天气详情与城市搜索
    weekly/                 冒险周报、精灵建议与分享卡片
    settings/               设置
  widgets/                  通用卡片、图表、天气图形、罗盘
```

## 本地运行

> **路径注意**：Android Gradle 插件不支持项目路径包含非 ASCII 字符。
> 当前笔记目录含中文，直接在这里执行 `flutter build` 会报 “project path contains non-ASCII characters”。
> 请先把 `app/` 复制到纯英文路径（例如 `D:\zhengtu_app`）再构建；已经构建好的 APK 不受影响，可直接安装。

环境要求：

- Flutter 3.47+（Dart 3.13+）
- JDK 17
- Android SDK 36 / Build Tools 36
- 或 macOS + Xcode 运行 iOS

```bash
flutter pub get
flutter run
```

构建 APK：

```bash
flutter build apk --release
```

产物：`build/app/outputs/flutter-apk/app-release.apk`

### 演示数据构建

用于截图 / 展示，首次启动会写入一组示例手札、任务和账目（仅当数据库为空）：

```bash
flutter build apk --debug --dart-define=DEMO_MODE=true
```

正常构建不传该参数，不会写入任何示例数据。

### 国内网络

`android/settings.gradle.kts` 与 `android/build.gradle.kts` 已经优先使用阿里云 Maven 镜像；
Gradle 发行版使用腾讯云镜像。如果网络环境不同，可以改回官方仓库。

## 数据模型

**diaries**：`id, date(唯一), title, content, images(|分隔), mood, created_at, updated_at`

**tasks**：`id, title, note, type(main/side), priority(high/medium/low), due_date, done, completed_at, created_at`

**expenses**：`id, amount, category, note, spent_at, created_at`

**weather_cache**：`date(主键), payload(JSON), updated_at`

## 设计说明

- **暖纸 + 墨色**：浅色模式是奶油纸色，深色模式是墨夜；铜色作为主线强调，苔绿表示完成，陶土红表示逾期和支出。
- **字体**：标题使用 Noto Serif SC（已子集化，5.4 MB），数字和英文装饰使用 Cormorant Garamond。
- **天气图形**：全部由 `CustomPainter` 手绘（太阳、月牙、云、雨、雪、雷、雾），不依赖第三方图标包。
- **图表**：环形分类图与 7 日柱状图均为自绘，支持入场动画。
- **动效**：页面切换、勾选、月历切换、底部导航都有克制的过渡。
- **周报分享**：暗色卡片 + 铜色数据，固定 4:5 比例，适合发朋友圈 / 小红书。
- **备份 ZIP**：`data.json`（UTF-8，含记录与设置）+ `images/`（手札照片），恢复时走数据库事务。

## 备份格式

```text
zhengtu_backup_YYYYMMDD_HHmmss.zip
├── data.json        # app / schema / exported_at / settings / diaries / tasks / expenses
└── images/          # 2026-10-18_0.jpg 等，data.json 里以相对路径引用
```

恢复会清空当前表并重新写入，照片会解压到应用专属目录；建议先导出一次当前数据。

## 测试

```bash
flutter analyze
flutter test
```

当前单元测试覆盖金额格式化、日期工具、连续记录、模型序列化、WMO 天气码映射和周报聚合。

## 已知边界

- 账号、云同步、钥匙存储尚未实现（规划在第二阶段 / 未来愿景）。
- 天气为免费接口，网络异常时会显示缓存或错误占位。
- 图片只保存在本机，卸载应用会一并删除；备份 ZIP 未加密，请妥善保管。
- iOS 工程已配置权限与图标，但需要在 macOS + Xcode 上完成打包验证。

## 接下来

1. 云端同步与账号（Supabase / Firebase 均可）。
2. 给精灵接可选的大模型周报，无密钥时继续走本地规则。
3. 备份加密、分设备导出与自动备份。
4. 单篇手札分享卡片与模板切换。
5. 上架前的签名、隐私政策、商店素材。

---

写给每一个把日常生活当作冒险的人。
