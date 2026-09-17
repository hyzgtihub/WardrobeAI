# YISU 项目会话交接

更新时间：2026-09-17（Asia/Shanghai）

## 1. 当前任务

当前周期是“账号注册邮箱验证码”。目标是在创建账号页面内完成：填写邮箱和密码、发送邮件验证码、输入验证码、点击“创建账号”后统一校验并建立账号。

当前工作位置：

- 仓库主目录：`/Users/huyouzhen/Documents/衣橱APP`
- 功能工作树：`/Users/huyouzhen/Documents/衣橱APP/.worktrees/codex-garment-photo-upload`
- 当前分支：`codex/account-identity`
- 基线分支：`main`
- 远程分支：`origin/codex/account-identity`
- Pull Request：<https://github.com/hyzgtihub/WardrobeAI/pull/3>
- PR 状态：OPEN，目标为 `main`。上一次远端 CI 失败；本地修复后完整 131 项测试已全部通过，待提交推送并重跑 GitHub Actions。

本功能已经由用户完成真机验证并确认验收。当前任务是提交、推送 CI 修复，并在 GitHub Actions 全绿后请求用户合并授权。

## 2. 已完成的内容

### 2.1 Git 和分支

账号验证码功能包含两个提交：

- `474e26d feat: verify email during registration`
- `4e660a5 feat: harden email verification signup flow`

以上提交已经推送到 `origin/codex/account-identity`，并创建 PR #3。当前本地分支已包含最新 `origin/main`；修复提交前的实际关系为 `origin/main...HEAD = 0 3`（左侧落后 0，右侧领先 3）。

### 2.2 注册验证码流程

- 验证码没有独立页面，直接位于“创建账号”页面。
- 用户先填写邮箱、密码、确认密码并同意条款，再点击“获取验证码”。
- 客户端通过 Supabase `auth.signUp(email:password:)` 请求注册邮件验证码。
- 邮件模板使用 `{{ .Token }}` 输出 6 位验证码。
- 用户输入验证码后点击“创建账号”，客户端通过 `verifyOTP(..., type: .signup)` 完成验证和注册。
- 支持 60 秒重发倒计时、验证码过期/错误提示和重新发送。
- 日常登录仍为邮箱＋密码，不重复要求验证码。

### 2.3 Supabase、Resend 和域名

- Supabase 已开启 Email provider、允许新用户注册和 Confirm email。
- Email OTP 长度为 6 位，过期时间为 3600 秒。
- 注册确认邮件模板已改为中文验证码模板，正文使用 `{{ .Token }}`。
- 已使用 Resend 自定义 SMTP。
- 发信子域名为 `auth.huyouzhen.com`。
- 阿里云 DNS 中已配置 Resend 提供的 DKIM、SPF/Return-Path CNAME 以及 DMARC TXT 记录。
- Resend 页面已显示域名和相关 DNS 记录为 Verified，可发送邮件。
- Supabase 邮件发送限流曾调整为测试阶段适用值；继续测试前应以 Dashboard 当前配置为准，不依赖本文中的历史截图数值。
- 不要把 Resend API Key、SMTP Password、Supabase secret/service-role key 或数据库连接串写入本文、代码或 Git。

### 2.4 注册页交互优化

- 验证码输入框隐藏了原来的 `#` 图标。
- 占位文案改为“请输入邮件验证码”。
- 删除“修改邮箱”按钮。
- 发送验证码后邮箱仍可直接编辑；修改邮箱会自动清空旧验证码、倒计时和错误状态，并恢复密码输入。
- 如果 Supabase 明确返回 `emailAlreadyRegistered`，页面提示“该邮箱已注册，请直接登录”，并禁用密码、确认密码和发送验证码；修改邮箱后恢复。
- 请求验证码期间会捕获提交时的邮箱、密码和操作 generation，邮箱变化后旧请求不能恢复倒计时或污染新表单，包括 A→B→A 的情况。
- 校验验证码期间锁定邮箱，且使用相同 generation 防止旧校验结果污染新状态。
- 去除了 `RootView` 中重复的注册错误展示，注册错误在表单对应位置呈现。

### 2.5 Supabase 重复邮箱的安全语义

Supabase 开启 Confirm email 后，对“已确认的既有邮箱”再次调用 `signUp`，通常不会返回“邮箱已注册”错误，而会返回伪造/混淆后的成功用户对象，以防止邮箱枚举。因此客户端不能可靠判断邮箱是否已注册。

当前采用安全统一提示：

> 如果该邮箱尚未注册，验证码已发送；如果已经注册，请直接登录。

该提示在请求表面成功后出现。页面进入倒计时仅表示 Supabase 接受请求，不代表旧账号一定实际收到新验证码邮件。不要再尝试仅根据客户端 `signUp` 成功结果判断邮箱是否存在。

### 2.6 测试与审查

- 新增/更新了注册状态单元测试与认证 UI 测试。
- 统一提示测试严格走过 TDD：先因提示不存在而失败，实现后通过。
- generation 失效和校验期间锁邮箱也有状态测试。
- 完整认证相关单元/UI 测试在最终修复后重新运行，`xcodebuild` 退出码为 0。
- 通用 iOS Simulator 构建在最终修复后重新运行，退出码为 0。
- `git diff --check` 通过。
- 提交前代码审查发现两个异步竞态，修复后复审确认无剩余阻断问题。
- 用户已经完成真机注册验证码流程以及本轮优化的人工验收。

## 3. 当前卡住的问题

### 3.1 PR CI 待重跑

远端上一次 `iOS / test` 已失败。已完成根因修复：测试照片加入 App 资源、选择器 UI 测试跟随当前交互、明确串行 UI 测试、修正分类顺序，并消除 `SessionStore` actor 隔离 warning。推送后应等待新 CI；全绿后仍需用户明确授权才能合并。

### 3.2 两个用户本地 Xcode 文件仍未提交

工作树目前仍有以下本地修改：

- `YISU.xcodeproj/project.pbxproj`
- `YISU.xcodeproj/xcshareddata/xcschemes/YISU.xcscheme`

这些修改包含用户的真机 Development Team、签名或 Xcode/Scheme 自动生成差异。本轮提交有意排除了它们。不要运行 `git add .`，不要还原、覆盖、删除或强行清理；只有用户明确要求时才能处理。

### 3.3 最近验证

- 2026-09-14 本地按 CI 生成工程方式运行完整测试：131 项通过，0 失败，0 跳过。
- `SessionStore.eventTask` 改为主 actor 隔离属性，并使用 `isolated deinit` 取消任务；原 warning 已消除。
- 用户的 Development Team 和 Scheme 本地修改已从安全保存点恢复。

## 4. 下一步计划

1. 读取 PR #3 最新状态和 `iOS / test` 结果。
2. 如果 CI 失败：查看完整日志，复现失败，先写/确认回归测试，再做最小修复；修复后重新推送本分支。
3. 如果 CI 通过：向用户报告可合并状态，并等待用户明确授权合并。
4. 合并后确认 `main` 已包含 `474e26d` 和 `4e660a5`，再拉取/同步本地主目录。
5. 在处理 worktree 或删除分支前，先解决两个未提交 Xcode 文件的归属；禁止强制删除带有这些修改的工作树。
6. 账号验证码功能正式收尾后，再从最新 `main` 创建新的 `codex/...` 分支开始下一项产品工作。
7. 后续优先级可回到衣橱工具路线：搜索、筛选、智能集合（最近添加/最爱/当季）和分类浏览；开始前重新读取最新 PRD/需求清单并确认范围。

## 5. 踩过的坑

### 5.1 打开错工程会运行旧代码

- 本功能位于隐藏工作树，不在主目录当前 `main` 工作副本中。
- 真机调试必须打开：`/Users/huyouzhen/Documents/衣橱APP/.worktrees/codex-garment-photo-upload/YISU.xcodeproj`。
- 若打开 `/Users/huyouzhen/Documents/衣橱APP/YISU.xcodeproj`，会看不到尚未合并到 `main` 的最新功能，容易误判为“代码没更新”。

### 5.2 Supabase 防邮箱枚举会返回“伪成功”

- 开启 Confirm email 后，旧邮箱再次注册可能不会抛出 `user_already_exists` / `email_exists`。
- 因此仅靠客户端错误映射无法稳定显示“邮箱已注册”。
- 若未来产品坚持精确检查，必须通过受信任服务端使用管理员能力查询，但这会主动暴露邮箱存在性并引入枚举风险；不能把 service-role key 放进 iOS App。
- 当前统一提示方案是更简单、更安全的实现。

### 5.3 UI 倒计时不等于邮件一定发出

- “重新发送 58s”代表客户端收到表面成功并进入冷却状态。
- 对已注册邮箱，Supabase 可能为了隐私返回成功但不发送实际注册邮件。
- 产品文案不要写成无条件的“验证码已发送”。

### 5.4 异步请求存在 A→B→A 竞态

- 仅比较请求完成时的邮箱字符串不足以判断请求是否过期。
- 用户可以在请求期间把邮箱从 A 改为 B，再改回 A，旧请求仍会通过字符串比较。
- 解决方式是每次实际邮箱编辑都递增 operation generation；异步请求捕获提交时 generation，完成时必须一致才允许更新 UI。
- 请求参数也必须在 Task 创建前捕获，不能在异步闭包里继续读取可变的 `email`/`password`。

### 5.5 验证期间编辑邮箱会污染状态

- 原实现允许在 `.verifying` 时编辑邮箱，旧失败结果会在新邮箱表单上重新写入错误和重发状态。
- 当前在验证码校验期间锁定邮箱，并在结果落地前检查 generation 与提交邮箱。

### 5.6 测试缓存与沙箱可能制造假象

- 复用旧 DerivedData 曾运行到旧测试二进制，导致测试看似没有覆盖最新接口。
- 对关键 TDD 红灯使用独立/明确的 DerivedData，确认失败原因确实是功能缺失，而不是编译缓存。
- 新建空 DerivedData 会触发 SwiftPM 重新拉取依赖；网络受限时可能报 GitHub DNS 失败，这不是业务代码错误。
- CoreSimulator 和 `~/Library`/SwiftPM 缓存受沙箱限制时，`xcodebuild` 可能报 `CoreSimulatorService connection invalid` 或 `Operation not permitted`；需要授权后在沙箱外运行。
- `xcodebuild -quiet` 成功时可能只输出观察器信息，应以最终进程退出码 0 为准。

### 5.7 Git worktree 的 index 位于主仓库

- worktree 的 index 位于主仓库 `.git/worktrees/...`，沙箱内 `git add`/`commit` 可能因无法创建 `index.lock` 失败。
- 需要授权后重试，不要绕过 Git 锁。
- 始终显式暂存功能文件；本轮提交明确排除了两个 Xcode 本地文件。

### 5.8 旧交接方案已经失效

- 旧 HANDOFF 曾记录“固定验证码 123456、Debug 菜单、开发 Edge Function、独立验证码页面”等架构设想。
- 用户后来明确收缩为真实 Supabase 邮件验证码，并要求验证码直接放在注册页面。
- 后续不得按旧方案恢复固定测试验证码或独立验证码页，除非用户重新提出并批准新设计。

## 6. 关键文件

- 注册页面：`WardrobeApp/Features/Auth/SignUpView.swift`
- 注册/验证码状态：`WardrobeApp/Features/Auth/AuthSubmissionState.swift`
- 页面与 SessionStore 接线：`WardrobeApp/App/RootView.swift`
- Supabase Auth Repository：`WardrobeApp/Infrastructure/Supabase/SupabaseAuthRepository.swift`
- Supabase 错误映射：`WardrobeApp/Infrastructure/Supabase/SupabaseErrorMapper.swift`
- SessionStore：`WardrobeApp/App/SessionStore.swift`
- UI 测试依赖：`WardrobeApp/App/AppDependencies.swift`
- 状态测试：`WardrobeAppTests/Auth/AuthSubmissionStateTests.swift`
- 认证流程 UI 测试：`WardrobeAppUITests/AuthSessionFlowTests.swift`
- Supabase 本地配置：`supabase/config.toml`
- 本地确认邮件模板：`supabase/templates/confirmation.html`
- 当前 PR：<https://github.com/hyzgtihub/WardrobeAI/pull/3>

## 7. 新会话启动检查清单

```bash
cd /Users/huyouzhen/Documents/衣橱APP/.worktrees/codex-garment-photo-upload
git branch --show-current
git status --short
git log --oneline -6
git fetch origin
git rev-list --left-right --count origin/main...HEAD
gh pr view 3 --json state,mergeStateStatus,statusCheckRollup,url
```

预期重点：

- 当前分支应为 `codex/account-identity`。
- 两个 Xcode 文件可能仍显示为未提交，必须保留。
- 先确认 PR CI，再决定修复、合并或保留分支。
- 不要把本文中的历史测试结果当作新改动后的证明；任何修改后都应重新运行对应测试和构建。
