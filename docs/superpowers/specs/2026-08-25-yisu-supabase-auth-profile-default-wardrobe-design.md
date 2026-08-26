# 衣序 Supabase 认证、用户资料与默认衣橱设计

## 1. 目标与交付边界

本阶段将当前 SwiftUI 演示登录替换为真实 Supabase 会话，并为每个新用户持久化基础资料与唯一默认衣橱“我”。

本阶段交付：

- 邮箱密码注册、登录、App 重启后会话恢复、退出。
- `profiles` 资料读取与基础更新能力。
- `wardrobes` 中每位用户的唯一默认衣橱“我”。
- 数据库迁移、RLS 策略、跨用户隔离测试和 Swift 单元测试。

不包含：衣物 CRUD、图片存储、P09 自动保存、离线同步、忘记密码、邮箱验证、注销账号。

## 2. 关键决策

- 客户端使用 Supabase Swift SDK 直连 Auth 和 PostgREST，数据库 RLS 是最终授权边界。
- App 只配置 Project URL 与 Publishable Key；`service_role` 永不进入 iOS 客户端。
- 邮箱的权威数据源是 `auth.users.email`，`profiles` 不重复保存邮箱。
- 开发阶段关闭强制邮箱验证，注册成功直接返回会话；邮箱验证作为后续独立里程碑。
- Supabase SDK 默认的安全会话存储与 token 刷新机制负责会话持久化；UI 不自行保存 token。
- 登录后由根级 `SessionStore` 驱动路由，View 不直接调用 Supabase。

## 3. 数据模型

### `public.profiles`

| 字段 | 类型 | 约束 |
| --- | --- | --- |
| `id` | `uuid` | 主键，引用 `auth.users(id) on delete cascade` |
| `nickname` | `text` | 非空，默认“衣序用户”，去空格后 1–30 字符 |
| `avatar_path` | `text` | 可空，本阶段不上传头像 |
| `language_code` | `text` | 非空，默认 `zh-Hans` |
| `notifications_enabled` | `boolean` | 非空，默认 `true` |
| `created_at` | `timestamptz` | 非空，默认 `now()` |
| `updated_at` | `timestamptz` | 非空，由触发器维护 |

### `public.wardrobes`

| 字段 | 类型 | 约束 |
| --- | --- | --- |
| `id` | `uuid` | 主键，默认 `gen_random_uuid()` |
| `owner_id` | `uuid` | 非空，引用 `auth.users(id) on delete cascade` |
| `name` | `text` | 非空，默认“我” |
| `is_default` | `boolean` | 非空，默认 `true` |
| `created_at` | `timestamptz` | 非空，默认 `now()` |
| `updated_at` | `timestamptz` | 非空，由触发器维护 |

`wardrobes` 建立部分唯一索引 `unique(owner_id) where is_default = true`，保证每位用户最多一个默认衣橱。本阶段不提供创建额外衣橱的客户端接口。

## 4. 自动建档与幂等性

`auth.users` 新增用户后，`security definer` 数据库函数在同一事务中：

1. 向 `profiles` 插入同 ID 资料。
2. 向 `wardrobes` 插入名称为“我”的默认衣橱。

插入使用 `on conflict do nothing`，并由主键与部分唯一索引保证重试幂等。触发函数将 `search_path` 固定为空并对对象使用完整 schema 名，避免权限提升函数的名称解析风险。

## 5. RLS 与权限

`profiles` 和 `wardrobes` 必须启用 RLS，策略只授权 `authenticated` 角色：

- `profiles select`：`auth.uid() = id`。
- `profiles update`：`using (auth.uid() = id)` 且 `with check (auth.uid() = id)`。
- `profiles insert/delete`：客户端不授权，由建档触发器和账号生命周期处理。
- `wardrobes select`：`auth.uid() = owner_id`。
- `wardrobes insert/update/delete`：本阶段客户端不授权。

验收必须包含用户 A 无法读取或更新用户 B 的 profile，且无法读取 B 的 wardrobe。Publishable Key 独立请求不能读取任何记录。

## 6. Swift 客户端边界

### 核心模型

```swift
struct AuthenticatedUser: Equatable, Sendable {
    let id: UUID
    let email: String
}

struct UserProfile: Codable, Equatable, Sendable {
    let id: UUID
    var nickname: String
    var avatarPath: String?
    var languageCode: String
    var notificationsEnabled: Bool
    let createdAt: Date
    var updatedAt: Date
}

struct WardrobeIdentity: Codable, Equatable, Sendable {
    let id: UUID
    let ownerID: UUID
    let name: String
    let isDefault: Bool
}
```

### 服务接口

```swift
protocol AuthRepository: Sendable {
    func sessionEvents() -> AsyncStream<AuthSessionEvent>
    func currentUser() async throws -> AuthenticatedUser?
    func signUp(email: String, password: String) async throws -> AuthenticatedUser
    func signIn(email: String, password: String) async throws -> AuthenticatedUser
    func signOut() async throws
}

protocol ProfileRepository: Sendable {
    func fetchProfile() async throws -> UserProfile
    func updateProfile(_ changes: ProfileChanges) async throws -> UserProfile
}

protocol WardrobeRepository: Sendable {
    func fetchDefaultWardrobe() async throws -> WardrobeIdentity
}
```

Supabase 实现放在 `Infrastructure/Supabase`，特性层只依赖协议。测试使用可控的 Mock，不让单元测试访问网络。

## 7. 会话状态与路由

`SessionStore` 为 `@MainActor @Observable` 对象，状态为：

```swift
enum SessionState: Equatable {
    case restoring
    case signedOut
    case loadingAccount(AuthenticatedUser)
    case ready(UserAccount)
    case failed(SessionFailure)
}
```

启动流程：

1. App 显示无业务闪烁的恢复态。
2. `currentUser()` 尝试恢复并刷新会话。
3. 无会话进入 `signedOut`，显示 P01。
4. 有会话则并发读取 profile 和默认 wardrobe，成功进入 `ready`并显示 P05。
5. 建档数据暂时不可见时做有上限的短重试；仍失败则进入可重试错误态。

`SessionStore` 持续监听 Auth 事件。收到 signed-out 或无法刷新的会话后，清除内存中的 profile/wardrobe 并返回 P01。本阶段无本地业务数据库，因此不涉及未同步草稿。

## 8. UI 集成和错误映射

- `RootView` 改为按 `SessionState` 显示恢复、登录或已登录内容，不再以登录回调直接跳转。
- `SignInView` 与 `SignUpView` 保留现有表单视觉和本地校验，提交改为 async ViewModel/SessionStore 动作。
- 注册成功后等待 profile 和默认衣橱可读，然后进入 P05；不再让本地 P03/P04 模拟决定最终成功。
- 已有 UI 启动参数保留，UI 测试可注入 Mock 会话，避免依赖真实 Supabase 账号。

领域错误映射：

- 无效凭据 → “邮箱或密码不正确”。
- 邮箱已存在 → 现有 `emailExists` 态。
- 超时/网络失败 → 保留输入，显示可重试错误。
- 会话过期且刷新失败 → 返回登录页。
- profile/wardrobe 读取失败 → 保留有效会话，显示账户加载重试页。

## 9. 配置与环境

- `Config/Secrets.xcconfig.example` 只提供占位符。
- `Config/Secrets.xcconfig` 被 Git 忽略，存放开发项目 URL 与 Publishable Key。
- build settings 以 Info.plist 键注入 App，`SupabaseConfiguration` 在启动时校验缺失值并返回明确的配置错误。
- 日志不输出 token、密码、完整邮箱或 Publishable Key。

## 10. 测试和验收

### 数据库

- 迁移在空数据库成功执行。
- 新建 Auth 用户后恰好有一条 profile 和一个名为“我”的默认 wardrobe。
- 用户 A 只能读取/更新自己的 profile，只能读取自己的 wardrobe。
- 未认证请求无法读取两张表。
- 重复建档不会生成第二个默认衣橱。

### Swift

- `SessionStore` 覆盖无会话、恢复成功、登录失败、建档读取重试、退出和 Auth 事件退出。
- Auth/Profile/Wardrobe repository 解码和错误映射有单元测试。
- UI 测试使用 Mock 覆盖 P01 登录成功进入 P05、注册失败保留输入、退出返回 P01。
- 最终执行完整 build、单元测试、UI 测试与 `git diff --check`。

## 11. 实施顺序

1. 引入 Supabase Swift 与安全配置读取。
2. 创建 Supabase CLI 项目骨架、SQL 迁移、触发器和 RLS 测试。
3. 定义领域模型、Repository 协议与 Mock。
4. 以 TDD 实现 `SessionStore` 状态机。
5. 实现 Supabase Auth/Profile/Wardrobe repositories。
6. 将 P01/P02 和 `RootView` 接入真实会话，保留 UI 测试注入通道。
7. 在开发 Supabase 项目执行端到端验收。

## 12. 非目标与后续接口

本设计不预先实现衣物、图片或离线队列。`WardrobeIdentity.id` 将作为下一阶段 `garments.wardrobe_id` 的外键，`UserProfile.avatarPath` 保留为后续私有 Storage 对象路径，不在本阶段引入上传逻辑。
