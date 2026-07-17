# AI 数字衣橱 MVP 详细实施计划（中文）

> **已废止：** 请勿执行本 SwiftUI 计划。客户端已于 2026-07-17 调整为 Flutter/Dart；本文件仅保留历史，等待新的 Flutter 实施计划替代。

> 执行要求：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans，严格按任务顺序实施，每完成一个任务独立测试、评审和提交。

## 目标与架构

目标是交付可供 30–50 名种子用户通过 TestFlight 测试的 iPhone MVP：单件衣物拍照后可自动去背景和识别，支持私密云端衣橱、多角色、搭配、OOTD、分享和会员订阅。

客户端采用 iOS 17+、Swift 6、SwiftUI、SwiftData 和按功能拆分的 MVVM + Repository。Supabase 提供 Apple 登录、Postgres、行级安全、私密 Storage 和 Edge Functions。Edge Functions 调用 remove.bg 与 OpenAI，第三方密钥绝不进入客户端。

技术版本锁定：XcodeGen 2.45.4、Supabase Swift 2.46.0、OpenAI 模型 gpt-4.1-mini-2025-04-14。Bundle ID 为 com.huyouzhen.wardrobe，StoreKit 月订阅 ID 为 com.huyouzhen.wardrobe.pro.monthly。

## 全局约束

- 免费版：1 个角色、累计 50 次成功 AI 录入；Pro：5 个角色、每月 1,000 次成功 AI 录入。
- AI 失败不能阻断录入，用户必须能使用原图手动填写并保存。
- 所有衣物、搭配和 OOTD 查询必须限定当前角色，禁止跨角色混合。
- 图片默认私密，客户端仅获取限时签名地址；只有用户主动点击时才生成分享图。
- 最近添加为过去 30 天；季节按北半球月份计算；服务端保存 UTC，界面显示设备时区。
- MVP 只实现“分类 + 衣物卡片”融合首页；视图切换、社区、自动搭配和虚拟试穿后置。

## 目录与接口

- project.yml、Config/*.xcconfig：Xcode 工程与环境配置。
- WardrobeApp/App：应用入口、导航、会话与当前角色。
- WardrobeApp/Core：模型、Repository 协议、网络、上传队列、图片分析、订阅。
- WardrobeApp/Features/{Auth,Roles,Wardrobe,Capture,Outfits,OOTD,Settings}：功能模块。
- WardrobeAppTests、WardrobeAppUITests：单元、集成和 UI 测试。
- supabase/migrations：数据库结构、RLS、Storage、额度和删除流程。
- supabase/functions/process-garment：衣物 AI 管线。
- supabase/functions/delete-account：账号数据删除。

共享接口名称必须与英文计划一致：AuthRepository、RoleRepository、GarmentRepository、ImportRepository、OutfitRepository、OOTDRepository、EntitlementService。后续任务不得自行改名。

### 任务 1：iOS 工程、测试与 CI 基线

文件：project.yml、Config/Debug.xcconfig、Config/Release.xcconfig、WardrobeApp/App/WardrobeApp.swift、RootView.swift、WardrobeAppTests/SmokeTests.swift、.gitignore、.github/workflows/ios.yml。

- [ ] 先写 testRootShowsSignedOutState，断言未登录时存在辅助功能 ID auth.signInWithApple。
- [ ] 运行 xcodegen generate 和 xcodebuild test；RootView 实现前必须失败。
- [ ] 建立最小 SwiftUI 入口，Supabase URL 和 publishable key 从不提交的 Secrets.xcconfig 注入，并提交 Secrets.xcconfig.example。
- [ ] CI 使用同一 xcodebuild 命令，只缓存 Swift Package Manager 下载。
- [ ] 全部通过后提交：chore: bootstrap iOS app and CI。

### 任务 2：数据库、私密存储与数据隔离

文件：supabase/config.toml、migrations/202607170001_core_schema.sql、supabase/tests/rls.sql、Core/Models/*.swift、ModelCodingTests.swift。

- [ ] 先写 pgTAP：用户 A 无法读写用户 B 的角色、衣物、搭配、OOTD 和图片；搭配/OOTD 只能引用同角色衣物。
- [ ] 创建角色、衣物、搭配、搭配项、OOTD、OOTD 项表，以及 role_type、garment_status、repurchase_rating、processing_status 枚举。
- [ ] 创建 role_id + created_at、category、last_worn_at 索引。
- [ ] 新用户触发器自动创建“我”；所有业务表启用基于 auth.uid() 的 RLS。
- [ ] 创建 garment-originals、garment-cutouts、ootd-photos 私密桶，路径第一段必须为用户 ID。
- [ ] 运行 supabase test db 和模型编码测试，提交：feat: add wardrobe schema and tenant isolation。

### 任务 3：Apple 登录、会话恢复与角色上下文

文件：SupabaseClientFactory.swift、AuthRepositoryLive.swift、SignInView.swift、SessionStore.swift、RoleRepositoryLive.swift、RoleSwitcher.swift 及测试。

- [ ] 测试 nonce、Apple token 转发、会话恢复、默认角色、角色切换持久化和退出重置。
- [ ] 实现 SignInWithAppleButton、SHA-256 nonce 和 Supabase Apple ID token 登录。
- [ ] 登录后 CurrentRoleStore.roleID 必须始终有效；切换角色后衣橱、搭配和 OOTD 同步切换。
- [ ] 免费用户创建第二个角色时只展示付费页，不向数据库提交。
- [ ] 单元和注入假 Repository 的 UI 测试通过后提交：feat: add authentication and role context。

### 任务 4：融合衣橱首页、筛选和智能标签

文件：GarmentRepositoryLive.swift、WardrobeViewModel.swift、WardrobeHomeView.swift、GarmentCard.swift、GarmentFilterSheet.swift、GarmentDetailView.swift、SmartLabelResolver.swift 及测试。

- [ ] 固定时钟测试最近添加、最近穿过、当季衣物和卡片最多两个标签；用户主动标签优先。
- [ ] GarmentFilter 支持文本、品类、季节、颜色、状态和智能集合。
- [ ] 实现角色切换、搜索、筛选、录入、智能集合、品类和三列衣物卡片，以及加载、空白和错误状态。
- [ ] 删除前通过 RPC 返回关联搭配/OOTD 数量；确认后保存历史快照，再删衣物和图片。
- [ ] 单元、快照和无障碍测试通过后提交：feat: add searchable smart wardrobe。

### 任务 5：拍照、画质检查和断网续传

文件：CameraView.swift、PhotoSourceSheet.swift、ImageQualityAnalyzer.swift、ImportDraftView.swift、UploadJob.swift、UploadQueue.swift、UploadWorker.swift 及测试。

- [ ] 使用样本测试模糊阈值 Laplacian 方差 <80、过暗阈值平均亮度 <0.12、无效数据、重复点击和重启恢复。
- [ ] 重试退避固定为 2、4、8、16、30 秒。
- [ ] 实现 PhotosPicker 和 AVFoundation；图片转 sRGB JPEG，长边不超过 2048 px，质量 0.85。
- [ ] JPEG 暂存 Application Support，任务元数据写入 SwiftData；上传路径为 user-id/job-id/original.jpg。
- [ ] 服务端完成前不得删除本地原图；测试飞行模式、切后台、恢复网络和重复保存。
- [ ] 提交：feat: add resilient garment import queue。

### 任务 6：服务端去背景与衣物识别

文件：process-garment/index.ts、providers/remove-bg.ts、providers/openai.ts、schema.ts、index.test.ts、202607170002_import_jobs.sql。

- [ ] Deno 测试无效身份、越权路径、重复任务、供应商失败、非法 AI 输出、额度耗尽和成功路径。
- [ ] import_jobs 状态固定为 queued、processing、needs_review、failed。
- [ ] 实现原子 reserve_ai_import(job_id)；只对成功处理计数，重复任务不重复扣额度。
- [ ] remove.bg 使用 size=auto；OpenAI 严格返回 category、subcategory、primaryColor、seasons 和 0–1 置信度。
- [ ] 任一供应商失败时保留原图并进入 needs_review，不向客户端暴露供应商错误正文。
- [ ] Deno 与本地 stub 集成测试通过后提交：feat: process garment images securely。

### 任务 7：AI 结果确认与手动兜底

文件：ImportReviewView.swift、ImportReviewViewModel.swift、ManualGarmentForm.swift 及单元/UI 测试。

- [ ] 测试 AI 预填、所有字段可改、原图兜底、必填品类、修改标记、重复提交幂等。
- [ ] 实现任务轮询和回前台刷新；失败时显示“手动填写并保存”。
- [ ] 用户确认的数据才写入正式衣物；任一建议被修改时记录 was_ai_corrected。
- [ ] 成功、部分失败、完全失败、离线恢复测试通过后提交：feat: add garment review and fallback。

### 任务 8：搭配、OOTD 和删除安全的历史

文件：Features/Outfits/*、Features/OOTD/*、202607170003_history_snapshots.sql 及测试。

- [ ] 测试搭配至少两件衣物、同角色引用、每角色每日一条 OOTD，以及修改/删除后 last_worn_at 重算。
- [ ] 实现衣物网格选取、搭配预览、月历、日期详情和可选用户照片。
- [ ] 数据库触发器/RPC 更新 last_worn_at。
- [ ] 为历史项保存 name、category、cutout_path 快照，衣物删除后仍可展示历史。
- [ ] 数据库、单元和 UI 测试通过后提交：feat: add outfits and OOTD history。

### 任务 9：主动分享与隐私

文件：ShareRenderer.swift、OutfitShareView.swift、OOTDShareView.swift、ShareRendererTests.swift。

- [ ] 测试输出 1080×1350，只含用户选择的衣物、日期和文案，不含私密 URL/元数据，并可用缓存离线生成。
- [ ] 使用 SwiftUI ImageRenderer；只有用户明确点击后才调系统分享面板。
- [ ] 设置页展示权限用途和隐私链接，不建立公开 Feed。
- [ ] 检查浅色、深色和动态字体后提交：feat: add private opt-in sharing。

### 任务 10：StoreKit、会员和额度

文件：StoreKitEntitlementService.swift、PaywallView.swift、Wardrobe.storekit、sync-entitlement/index.ts、202607170004_entitlements.sql 及测试。

- [ ] 测试购买、恢复、过期、账单重试、离线缓存、1/5 角色限制、50/1,000 AI 额度和降级。
- [ ] 使用 StoreKit 2 验证交易并同步服务端，额度以服务端判断为准。
- [ ] 降级后不删数据，只允许编辑最近使用的角色；AI 额度用完后仍可手动创建。
- [ ] StoreKit 和数据库额度测试通过后提交：feat: add subscription entitlements。

### 任务 11：账号删除、埋点、监控和 TestFlight

文件：delete-account/index.ts、AccountView.swift、Analytics.swift、AppLogger.swift、PrivacyInfo.xcprivacy、测试和 docs/release/testflight-checklist.md。

- [ ] 测试二次确认、重新认证、Storage/业务数据/Auth 用户删除和重试幂等。
- [ ] 埋点不得包含图片、自由文本、孩子姓名或原始用户 ID。
- [ ] 事件固定为登录完成、首次录入、衣物保存、创建搭配、创建 OOTD、创建角色、额度触达和购买完成。
- [ ] 监控 remove.bg、OpenAI 和总处理耗时；15 分钟错误率 >5% 或 p95 >30 秒告警。
- [ ] 跑通登录→录入→修正→付费→宝宝衣物→搭配→OOTD→分享→重启恢复→注销。
- [ ] 全量 xcodebuild、supabase 和 Deno 测试通过；Release Archive 零警告，完成隐私清单和 TestFlight 检查。
- [ ] 提交：chore: harden MVP for TestFlight。

## 分阶段交付门禁

1. Gate A（任务 1–4）：登录、角色隔离、衣物 CRUD 和融合首页完成。
2. Gate B（任务 5–7）：断网安全的 AI 录入完成，在种子用户区域达到 p95 30 秒。
3. Gate C（任务 8–9）：搭配、OOTD、历史和主动分享完成。
4. Gate D（任务 10–11）：会员、额度、注销、监控、无障碍和全量回归通过，可提交 TestFlight。

## 产品验证默认值

- 首批 TestFlight 为 30–50 人，观察 14 天后再制定留存目标。
- 免费/Pro 额度是首轮测试默认值，后续可在不改表结构的情况下调整。
- Supabase 区域须在确认运营主体和发布地域后选择。
- 公开上线前必须完成跨境图像处理、儿童相关数据和隐私政策的法务审查。
- remove.bg 和 OpenAI 均通过供应商接口隔离，可替换为境内服务而不修改 iOS 功能代码。

英文原版仍为完整接口与任务合同；中文版本与其任务编号、版本、阈值、提交点和验收门禁保持一致。若两版文字出现解释差异，以已批准的产品设计和英文计划中的精确接口签名为准。
