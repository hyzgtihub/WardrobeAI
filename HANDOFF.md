# YISU 项目会话交接

更新时间：2026-09-08（Asia/Shanghai）

## 1. 新会话应从哪里继续

- 工作目录：`/Users/huyouzhen/Documents/衣橱APP/.worktrees/codex-garment-photo-upload`
- 当前分支：`codex/garment-photo-upload`
- 用户已明确要求：先在本分支完成交接同步提交，再从该提交创建账号身份完善的新分支；不合并、不推送、不清理 worktree。
- 当前正在进行的工作不是编码，而是下一开发周期的架构级需求确认。
- 下一会话先阅读本文，然后继续第 7 节中的“尚待用户确认的问题”。在设计获得明确批准前不要开始实现。

## 2. Git 与本地修改状态

最近已提交的完整功能区间：`0f1b641` 至 `8f8c602`。

关键提交：

- `273163a feat: persist editable garment fields`
- `1cab02e feat: define garment field selection policies`
- `6cb0b76 feat: add garment field pickers`
- `9565213 fix: isolate garment creation drafts`
- `75022e5 feat: complete editable garment details`
- `2e4806a docs: align garment editing requirements`
- `1907d5c fix: expose explicit garment save retries`
- `c9856bb fix: serialize dependent garment operations`
- `8f8c602 fix: avoid sendable photo label capture`

以下两个未提交文件属于用户的真机签名和 Scheme 配置，必须保留，未经用户明确要求不要覆盖、还原或暂存：

- `YISU.xcodeproj/project.pbxproj`
- `YISU.xcodeproj/xcshareddata/xcschemes/YISU.xcscheme`

其中包含用户 Development Team 配置及 Xcode/Scheme 生成差异。执行提交时继续使用显式文件列表，避免 `git add .`。

本文件 `HANDOFF.md` 是本次新建的交接文件，目前尚未提交。

## 3. 当前已完成的产品能力

### 3.1 工程、账号和默认衣橱

- SwiftUI、Swift 6、iOS 17+ 工程和衣序 YISU 设计系统。
- 邮箱密码注册、登录、会话恢复和退出登录。
- Supabase 用户资料、昵称修改和唯一默认衣橱“我”。
- 新账号资料/默认衣橱初始化，账号之间通过 RLS 隔离。
- “衣橱｜添加衣物｜我的”三栏主导航。

### 3.2 衣物创建 P07/P08

- 从系统相册选择、取消、重新选择和照片预览。
- JPEG 转换、最大边缩放、压缩及 EXIF/GPS 等隐私元数据清理。
- 私有 Storage 上传、数据库创建和失败补偿删除。
- 防重复提交；上传/创建失败保留当前表单。
- 从 P05 开始第二次添加时使用全新空草稿，不再预填上一件衣物。
- 创建成功后进入真实 P09 详情页。
- 已支持字段：名称、分类、季节、收纳位置、备注、颜色、品牌、价格、尺码、购买日期、材质、风格。
- 分类、尺码、季节、颜色、材质、风格和收纳位置使用选择控件，不再使用错误的自由文本输入。
- 单选即时完成；多选点击“完成”才提交；取消不改变原值。
- 分类与尺码联动：服装/鞋履/无尺码分类切换时按规则提示并清除。
- 材质、风格已改为数组字段。

### 3.3 自定义购买日期日历

- 衣序自定义 6 行月历，不使用原生 `DatePicker`。
- 周一开头，未来日期不可选。
- 周末与普通可选工作日使用相同颜色，避免与未来禁用日期混淆。
- 支持选择相邻月份中的过去日期、月份导航和清除日期。
- P08 与 P09 共用同一套日历规则和组件。
- 已选日期高保真参考图：`docs/superpowers/specs/assets/2026-09-05-yisu-purchase-date-selected.png`。

### 3.4 衣物详情 P09 与自动保存

- P09 即查看即编辑，无独立编辑页和统一保存按钮。
- 名称、品牌、价格、备注为文本编辑；名称停止输入约 800 ms 或失焦后提交。
- 选择型字段完成选择后立即局部 PATCH。
- 无变化不请求；名称不能为空；价格必须非负且最多两位小数。
- 同一逻辑字段串行保存，最新页面值不会被旧响应覆盖；不同字段可独立提交。
- 分类和尺码共用同一串行通道，避免清空尺码被旧请求恢复。
- 保存成功后只用服务端成功值更新 P05；失败值不污染首页。
- 保存失败保留当前会话值，不自动重试、不写持久化待同步队列，并提供主动重试。
- 账号退出/切换时取消旧详情 Store 的待处理任务，避免跨账号提交。

### 3.5 P09 换图和删除

- 系统选图后需要二次确认；取消时原图不变。
- 新图片使用 `<user>/<garment>/<revision>.jpg` 私有修订路径。
- 上传新图 → PATCH `image_path` → 成功后切换 P09/P05 图片 → 清理旧对象。
- PATCH 失败时补偿删除新对象并继续显示旧图；当前会话可主动重试。
- 重复换图操作受保护，不会并发上传/覆盖。
- 删除有二次确认；先确保私有图片清理成功，再删除数据库记录；成功后才从 P05 移除。

### 3.6 Supabase

- 已有 `profiles`、默认 `wardrobes`、`garments` 和私有 `garment-images`。
- 已实现衣物 fetch/create/partial update/delete Repository。
- 迁移 `202609050001_garment_editing_fields.sql` 已部署到已链接项目 `yisu-dev`。
- `materials`、`styles` 为 `text[]`，包含数组项数及单项去空白长度约束。
- 本地和远端迁移记录已确认一致：`202608260001`、`202608270001`、`202609030001`、`202609050001`。
- 不要把 Supabase 密钥、数据库连接串或 CLI 状态输出写进本文或代码。

## 4. 最近验证结果

功能完成时执行并通过：

- 完整 `xcodebuild test`（Swift 单元测试和现有 UI 测试）。
- 通用 iOS Simulator 构建。
- `supabase test db`：2 个测试文件、34 项 pgTAP/RLS 测试全部通过。
- `supabase migration list`：本地/远端 4 个迁移版本一致。
- `git diff --check`。
- `plutil -lint Config/AppInfo.plist`。

用户随后已在真机完成一轮人工验证，反馈“目前整体逻辑基本跑通”。新周期开始前仍建议重新运行相关测试，不要把以上历史证据当成未来改动后的通过证据。

2026-09-08 交接提交前重新运行完整 `xcodebuild test`：共 118 项，111 项通过、7 项失败。已确认失败不是本次文档同步引入，但新分支不得将测试基线记为全绿：

- `ModelTests/categoryOrderMatchesGateB4()` 仍断言旧分类文案与顺序，与当前冻结的“全部、上衣、裤子、连衣裙、外套、鞋履、包袋、配饰、其他”不一致。
- 5 项添加衣物相关 UI 测试仍寻找旧的 `addGarment.category.tops` 按钮，未适配当前选择器交互。
- `GarmentDetailTests/testP05CardOpensEditableP09()` 有一项 `XCTAssertTrue` 失败，需在新分支开始实现前复现并定位。

当前构建存在一个既有非阻塞 warning：

```text
SessionStore.swift: 'nonisolated(unsafe)' has no effect on property 'eventTask'
```

该 warning 不是本轮衣物功能造成，但进入 Release 收尾时应处理。

## 5. 原始项目计划与当前进度定位

最初 11 任务 MVP 包含 Apple 登录、多角色、相机/画质检查、离线续传、AI 去背景与识别、搭配/OOTD、分享、StoreKit、账号注销、埋点监控和 TestFlight。后来产品范围明确收缩为 Gate A：邮箱密码、唯一默认衣橱“我”、系统相册、私密云端衣物 CRUD 和 P09 自动保存。

因此当前约为：

- 按收缩后的 Gate A：80%–90%。
- 按最初完整 11 任务 MVP：30%–35%。

原始计划中尚未完成或明确后置：

- Apple 登录、多角色和会员角色限制。
- 相机拍摄、模糊/过暗/多件检测、离线任务恢复。
- AI 去背景、属性识别、AI 结果确认、纠错和额度。
- 搭配、完整 OOTD、穿着历史及删除历史快照。
- 分享图和系统分享。
- StoreKit、订阅和权益同步。
- 账号注销、完整埋点/监控、Release Archive/TestFlight 发布门禁。

注意：最初 PRD/计划仍可能保留已经被后续 Gate A 设计覆盖的描述。开发时以最新已确认规格为准，不要直接照旧计划恢复多角色、离线队列或自动重试。

## 6. 下一开发周期：已确认范围

这是架构级周期，必须先完成设计规格和实施计划，再编码。用户确认按以下顺序推进。

### 子项目 A：账号身份完善（先做）

已确认：

- 邮件验证码只用于新用户注册和敏感账号操作。
- 日常登录只使用邮箱＋密码，不重复验证邮件。
- 敏感操作范围：修改登录邮箱、重置/修改密码、注销账号及删除云端数据。
- 修改展示昵称、头像和退出登录不需要验证码。
- Debug 构建提供专用开发菜单，可切换真实邮件验证码/固定测试验证码。
- Release 构建强制真实验证码，不能关闭，也不包含测试绕过入口。
- 固定测试验证码为 `123456`。
- 测试模式不发邮件，验证码页面明确显示开发模式和测试码。
- 测试码输错按正常错误处理；连续错误 5 次后等待 30 秒；切回真实模式立即失效。
- 用户身份采用双字段：
  - `display_name`：界面展示，可重复，支持中文。
  - `username`：全局唯一、大小写不敏感，仅字母/数字/下划线，长度 4–20。
- 注册完成后自动生成类似 `yisu_7k3m9q` 的唯一用户名，用户以后可修改。
- `display_name` 为空时回退显示 `username`。
- 唯一用户名修改时先检查占用，数据库唯一约束做最终保证。

### 子项目 B：衣橱工具路线（账号身份完善之后）

搜索已确认：

- 匹配名称、品牌、分类、颜色、材质、风格和备注。
- 不区分大小写，忽略首尾空格，中文按包含匹配。
- 搜索与筛选可以叠加；清空搜索不清空筛选。
- 第一版针对当前已加载衣橱做即时本地搜索，数据规模增长后再考虑服务端搜索。

筛选已确认：

- 维度：分类、季节、颜色、材质、风格、尺码、收纳位置、是否最爱。
- 同一维度多选为“或”，不同维度之间为“且”。
- 搜索词和筛选结果之间为“且”。
- Sheet 内为临时状态，只有点击完成才应用；取消不改当前筛选。
- 显示生效条件数量，并支持一键清空。
- 第一版不提供购买日期和价格筛选。

智能集合已确认并经过一次范围修订：

- 保留：最近添加、最爱、当季衣物。
- 取消：“最近穿过”。
- 本周期也不实现基础穿着记录，统一后置到搭配/OOTD。
- 最近添加：过去 30 天。
- 当季：北半球规则，春 3–5 月、夏 6–8 月、秋 9–11 月、冬 12–2 月。
- 每个智能集合显示数量；空集合仍可进入并展示空状态。
- 最爱由用户主动设置，卡片和详情页均有入口。

分类浏览已确认：

- 首页横向分类栏，原地刷新网格，不进入独立分类页面。
- 顺序：全部、上衣、裤子、连衣裙、外套、鞋履、包袋、配饰、其他。
- 同时展示各分类数量。
- 分类筛选可与搜索及其他维度叠加。
- 多分类筛选时分类栏显示“多分类”。
- 点击单个分类只替换分类条件，不清空其他筛选。
- 分类为空时显示空状态和添加衣物入口。
- 卡片最爱按钮与进入详情的点击区域互不冲突。

### 后续阶段（不与工具路线同时铺开）

- 阶段 B：AI 图片处理和属性识别（P0）、AI 手动兜底、分享（P0）。
- 阶段 C：搭配和完整 OOTD（P1），包括穿着记录和历史快照。
- 发布运营能力贯穿所有阶段：日志、隐私、账号注销、埋点、监控、Release 和 TestFlight 门禁。

## 7. 当前卡点与尚待确认的问题

当前唯一正在等待用户确认的架构问题：

> 是否确认把当前已链接的 `yisu-dev` 定义为纯开发 Supabase 环境，并在正式发布前建立独立 Production Supabase 项目？

提出该问题的原因：

- 客户端接受 `123456` 不能让远端 Supabase 用户真正变成已验证状态。
- 绝不能把 `service_role` 或管理员权限放入 iOS App。
- 建议测试模式调用仅部署在开发项目的受限 Edge Function，由服务端验证 `123456` 并完成开发账号验证。
- Edge Function 需要频率限制，并限制为测试邮箱白名单或测试邮箱域名。
- Production 不启用测试 OTP、不部署可用的验证绕过配置；Release App 只连接 Production。

新会话应先把上面的问题原样问给用户。若用户确认，再继续账号身份子项目的其余设计：注册状态机、验证码重发/倒计时、敏感操作重新认证、唯一用户名冲突与保留词、错误处理、数据迁移和测试策略。完成设计后写规格并等待用户审阅；批准后才写实施计划。

## 8. 下一步计划

1. 取得第 7 节环境隔离问题的明确答复。
2. 完成“账号身份完善”的架构设计，至少覆盖：
   - Debug/Release 编译与运行时边界。
   - 真实 OTP 与开发 OTP Provider 接口。
   - Edge Function 安全策略、白名单、限流、日志脱敏。
   - 注册、重发、过期、输错、返回、App 重启状态机。
   - 修改邮箱/密码/注销时的重新验证。
   - `display_name`/`username` schema、规范化、唯一索引、保留词和迁移。
   - 单元、UI、数据库/RLS、真机和远端验收。
3. 输出并提交账号身份设计规格，交用户审阅。
4. 用户批准规格后编写详细实施计划，之后才执行代码。
5. 账号身份子项目完成并真机通过后，再为衣橱工具路线单独写规格/计划。
6. 工具路线完成后再进入 AI/分享；搭配/OOTD 最后实施。

## 9. 已踩过的坑

### Xcode 与真机

- 必须从上述 feature worktree 打开/运行工程；从主目录运行会看不到本分支的功能。
- 真机构建曾因未选择 Development Team 失败；用户已在 Xcode Signing & Capabilities 中配置团队。
- 首次安装个人开发证书需要在 iPhone“设置 → 通用 → VPN 与设备管理”中信任开发者证书。
- XcodeGen 或 Xcode 自动保存会重排 `project.pbxproj` 和 Scheme；这些文件当前含用户设置，不要机械还原。

### Swift 6 / SwiftUI

- `GarmentDetailView` 曾触发 Swift 编译器 IRGen 崩溃，而不是普通源码错误。
- 根因是把 `@MainActor` Store 方法引用直接转换为 Sheet/TextField 闭包，例如 `set: store.editName`、`store.setColors`。
- 修复方式是使用显式闭包，例如 `{ store.editName($0) }`。后续不要恢复直接方法引用写法。
- `PhotosPicker` 的 `@Sendable` label 闭包捕获主线程计算属性会产生隔离 warning；现已将标签内容内联。

### 自动保存与并发

- 不能让同一字段同时 PATCH；请求期间产生的新值必须进入最新待提交槽。
- 服务端旧响应不能覆盖用户正在编辑的 draft。
- 分类和尺码不是两个完全独立字段：切换分类并清除尺码必须走同一串行通道。
- 保存成功才更新 P05；失败页面值不能污染首页。
- 换图不能覆盖固定 `original.jpg`，否则数据库失败时无法恢复；必须使用 revision path。
- 换图 PATCH 失败要删除新对象；删除衣物时必须考虑图片对象清理顺序，防止孤立文件。

### Supabase 本地环境

- `supabase db reset` 曾结束但没有实际记录项目迁移，本地测试因此报所有业务表不存在。
- 可靠恢复命令是：`supabase db push --local --include-all`，确认迁移应用后再运行 `supabase test db`。
- 当前本地 Auth schema 没有测试旧写法中的 `email_confirmed_at` 列；pgTAP 测试插入用户时已移除该列。
- CLI 的 `status`/某些输出会显示本地开发密钥；不要复制到文档、聊天总结或提交记录。
- 本地容器镜像下载曾受 DNS/网络影响；失败时不要误判为迁移 SQL 错误。

### Git/worktree

- worktree 的 Git index 位于主仓库 `.git/worktrees/...`，受沙箱限制时 `git add/commit` 可能需要授权。
- 工作树存在用户修改时必须显式暂存目标文件，禁止 `git add .`。
- 不要运行 `git reset --hard`、`git checkout --` 或强制清理 worktree。

## 10. 关键文档

- 原始完整 MVP 计划：`docs/superpowers/plans/2026-07-17-ai-digital-wardrobe-mvp-zh-CN.md`
- 当前 PRD：`AI数字衣橱-PRD-20260717.md`
- 当前需求清单：`AI数字衣橱-需求清单-20260717.md`
- 照片上传规格：`docs/superpowers/specs/2026-09-03-yisu-garment-photo-upload-design.md`
- 照片上传计划：`docs/superpowers/plans/2026-09-03-yisu-garment-photo-upload.md`
- 字段选择/自动保存规格：`docs/superpowers/specs/2026-09-05-yisu-garment-editing-and-field-pickers-design.md`
- 字段选择/自动保存计划：`docs/superpowers/plans/2026-09-05-yisu-garment-editing-and-field-pickers.md`
