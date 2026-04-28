# Flutter 项目框架搭建设计

- **日期**：2026-04-27
- **目标**：在 `/Users/scream/weather-app` 搭建一个 Flutter 工程开发框架，作为后续天气 + 穿搭推荐应用「穿什么」的代码起点
- **范围**：仅工程骨架与基础设施，不包含任何 UI / 业务实现

## 1. 项目初始化

```bash
flutter create --org com.softandapp \
  --project-name weather_app \
  --platforms ios,android \
  --description "穿什么 - 天气穿搭推荐" \
  .
```

- 在已有目录 `/Users/scream/weather-app` 下执行，保留 `DESIGN.md`、`.claude/`、`docs/`
- 包名 / Bundle Identifier：`com.softandapp.weather_app`
- 项目内部 Dart 包名：`weather_app`
- 显示名（Android label & iOS CFBundleDisplayName）：**穿什么**

## 2. 目录结构（feature-based 轻量分层）

```
lib/
  main.dart                       # 入口，runApp(ProviderScope)
  app.dart                        # MaterialApp.router + theme

  core/
    theme/
      app_theme.dart
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_radius.dart
    router/
      app_router.dart
      routes.dart
    network/
      dio_client.dart
      interceptors/
        log_interceptor.dart
        error_interceptor.dart
    storage/
      preferences.dart
    location/
      location_service.dart
      permission_helper.dart
    error/
      app_exception.dart

  features/
    weather/
      view/
      controller/
      repository/
      model/
    outfit/
      view/
      controller/
      repository/
      model/

assets/
  fonts/                          # 当前为空，使用 google_fonts 动态加载

test/
  core/
  features/
```

空目录通过 `.gitkeep` 占位。

## 3. 依赖清单（pubspec.yaml）

```yaml
dependencies:
  flutter: { sdk: flutter }
  cupertino_icons: ^1.0.8

  # 状态管理
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # 路由
  go_router: ^14.2.0

  # 网络
  dio: ^5.4.3

  # 本地存储
  shared_preferences: ^2.2.3

  # 定位 + 权限
  geolocator: ^12.0.0
  permission_handler: ^11.3.1

  # 字体
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^4.0.0

  # Riverpod 代码生成
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.11
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.12
```

## 4. 主题落地（基于 DESIGN.md）

- `app_colors.dart`：把 `DESIGN.md` frontmatter 里的 50+ 个 Material 3 颜色 token 映射成一个 light `ColorScheme`
- `app_typography.dart`：根据 DESIGN.md 7 套字体样式（display / headline-h1 / headline-h2 / body-lg / body-md / label-caps / button）构建 `TextTheme`，fontFamily 使用 Plus Jakarta Sans（通过 google_fonts）
- `app_spacing.dart` / `app_radius.dart`：使用 `ThemeExtension` 注册到 `ThemeData.extensions`，便于后续无侵入扩展暗色 / 多主题
- 当前阶段仅实现 light theme

## 5. 字体方案

- 框架阶段使用 `google_fonts` 包动态加载 `Plus Jakarta Sans`，避免下载字体文件
- 在 `app_typography.dart` 顶部加注释说明：生产时如需离线字体，应将 ttf 放入 `assets/fonts/`，注册到 `pubspec.yaml`，并改用 `TextStyle(fontFamily: 'PlusJakartaSans', ...)`

## 6. 平台配置

### Android

- `android/app/build.gradle`：
  - `applicationId = com.softandapp.weather_app`
  - `minSdk = 23`，`targetSdk = 34`，`compileSdk = 34`
- `android/app/src/main/AndroidManifest.xml`：
  - `<application android:label="穿什么">`
  - 权限声明：
    - `android.permission.ACCESS_COARSE_LOCATION`
    - `android.permission.ACCESS_FINE_LOCATION`
    - `android.permission.INTERNET`（Flutter 默认会加，确认存在即可）

### iOS

- `ios/Podfile`：`platform :ios, '13.0'`
- `ios/Runner/Info.plist`：
  - `CFBundleDisplayName = 穿什么`
  - `CFBundleIdentifier`（通常引用 `$(PRODUCT_BUNDLE_IDENTIFIER)`，由 Xcode project 控制）
  - `NSLocationWhenInUseUsageDescription = 用于获取你当前位置的天气`
- `ios/Runner.xcodeproj/project.pbxproj`：
  - `PRODUCT_BUNDLE_IDENTIFIER = com.softandapp.weather_app`
  - `IPHONEOS_DEPLOYMENT_TARGET = 13.0`

## 7. 不在本次范围内（边界）

- ❌ 任何 UI 页面 / Demo
- ❌ 真实天气 API 接入与 provider 选型
- ❌ 暗色主题
- ❌ 国际化 / 推送 / 深链 / CI/CD
- ❌ 字体文件离线打包
- ❌ 应用图标、启动图

## 8. 验收标准

- `flutter analyze` 无错误
- `flutter pub get` 成功
- 工程能用 `flutter run` 启动到默认空白页（或最简白屏 Scaffold），无运行时崩溃
- 在 iOS / Android 上，应用名显示为「穿什么」，包名为 `com.softandapp.weather_app`
