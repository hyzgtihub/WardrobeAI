# 衣序（YISU）

衣序是一个 SwiftUI 数字衣橱应用。当前后端使用 Supabase Auth、Postgres 与行级安全策略，首批支持邮箱注册/登录、会话恢复、用户资料和默认衣橱持久化。

## 开发环境

- Xcode 26.3 或兼容版本
- iOS 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)
- Docker 或 Colima（运行本地 Supabase 数据库测试时需要）

## Supabase App 配置

复制配置模板：

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

在 `Config/Secrets.xcconfig` 中填写开发项目的 URL 和 Publishable Key：

```xcconfig
SUPABASE_URL = https:/$()/YOUR_PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY = YOUR_PUBLISHABLE_KEY
```

`$()` 用于保留 URL 的双斜杠；在 xcconfig 中直接写 `//` 会被解析为注释。

客户端只允许使用 Project URL 和 Publishable Key。禁止将 `service_role` key、数据库密码、用户密码、access token 或 refresh token 写入 App、日志或 Git 跟踪文件。`Config/Secrets.xcconfig` 已被 `.gitignore` 排除。

## 生成并运行 iOS 项目

```bash
xcodegen generate
open YISU.xcodeproj
```

在 Xcode 中选择 iOS 模拟器后运行 `YISU` scheme。首次运行会显示登录页；成功登录后会加载当前用户资料与默认衣橱。

## 本地 Supabase 数据库测试

```bash
supabase start
supabase test db
```

数据库测试覆盖用户注册后自动创建 profile 和默认衣橱、跨用户隔离以及匿名访问限制。

## iOS 构建与测试

```bash
xcodegen generate
xcodebuild build \
  -project YISU.xcodeproj \
  -scheme YISU \
  -destination 'generic/platform=iOS Simulator'

xcodebuild test \
  -project YISU.xcodeproj \
  -scheme YISU \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

UI 测试使用本地 Mock，不创建或修改远程 Supabase 用户。

## 应用远程迁移

仅在确认目标为开发项目后执行：

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push --dry-run
supabase db push
```

不要把数据库密码放入命令、脚本、README 或 shell 历史；需要时只在 Supabase CLI 的安全提示中输入。
