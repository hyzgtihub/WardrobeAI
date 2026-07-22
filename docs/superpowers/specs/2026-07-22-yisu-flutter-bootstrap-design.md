# YISU Flutter 工程初始化设计

## 目标

在仓库根目录创建独立的 `yisu/` Flutter 应用，支持 iOS 与 Android，并提供可验证的默认应用基线。

## 方案

- 使用 Flutter stable CLI 生成标准应用模板。
- 应用包名前缀使用开发期标识 `com.yisu.app`，项目名为 `yisu`。
- iOS 使用 Swift，Android 使用 Kotlin。
- 不修改仓库现有 PRD、交付物或其他未提交文件。

## 验收

- `flutter analyze` 通过。
- `flutter test` 通过。
- `flutter build ios --simulator` 成功。
- `flutter build apk --debug` 成功。

## 风险与边界

Apple Developer 会员、真机签名、TestFlight 和 Sign in with Apple 不属于本次初始化范围；发布前须确认 `com.yisu.app` 可作为最终 Bundle ID 使用。
