# YISU 项目会话交接

更新时间：2026-09-18（Asia/Shanghai）

## 1. 当前任务与工作位置

当前小周期为“衣橱分类浏览与组合筛选”。产品方向已经收敛为：不提供文本搜索框或独立搜索页，衣橱首页仅保留分类浏览和筛选弹窗。

- 仓库主目录：`/Users/huyouzhen/Documents/衣橱APP`
- 功能工作树：`/Users/huyouzhen/Documents/衣橱APP/.worktrees/codex-wardrobe-filtering`
- 当前集成分支：`main`
- 功能分支：`codex/wardrobe-filtering`
- 产品规格：`docs/superpowers/specs/2026-09-17-yisu-wardrobe-category-filtering-design.md`
- 实施计划：`docs/superpowers/plans/2026-09-17-yisu-wardrobe-category-filtering.md`

当前小周期的功能开发和真机验收已经完成。PR #4 已合并到 `main`。

## 2. 已完成内容

### 2.1 首页分类浏览

- 首页分类固定为：全部、上衣、裤子、连衣裙、外套、鞋履、包袋、配饰、其他。
- 分类只允许在首页横向标签栏中切换，筛选弹窗不再提供“分类”维度。
- 分类标签不再显示衣物数量，辅助功能标签也不包含数量。
- 点击分类只替换分类条件，保留季节、颜色等其他筛选条件。
- 分类条件不重复显示为顶部条件标签；仅选择分类时不显示筛选圆点。

### 2.2 组合筛选

- 不实现独立搜索页、文本搜索框或顶部搜索按钮。
- 首页提供筛选按钮；存在已应用的非分类条件时，按钮显示小圆点。
- 已应用条件以可移除标签横向展示；关闭筛选弹窗后仍保留本次已应用条件。
- 筛选面板采用底部弹窗形式。
- 当前可见筛选维度：季节、颜色、材质、风格、尺码、收纳位置。
- 同维度多选为“或”，不同维度为“且”。
- 季节使用固定选项；其他维度从当前已加载衣物中动态去重，自定义值也可筛选。
- 所有筛选选项均不再显示匹配数量，VoiceOver 标签也不再朗读数量。
- 关闭或下滑关闭会放弃未完成草稿；“完成”才应用；“重置”清空草稿后仍需点击“完成”才生效。
- 衣橱有数据但筛选无结果时，可以清空筛选或进入添加衣物流程。

### 2.3 筛选弹窗底部操作区

- “重置”位于左侧，固定较窄宽度，灰色文字、无边框、无背景。
- “完成”占右侧剩余宽度，高度为设计系统按钮高度（56pt），使用小圆角矩形。
- “完成”按钮保持应用主题色 `YISUTheme.Color.brandEmphasis`，不是黑色；文字为白色加粗。
- 两个按钮保持同一垂直中心，并满足最小点击区域要求。

### 2.4 会话生命周期与数据隔离

- 筛选状态在当前登录会话内保留；进入详情或添加流程再返回不会丢失。
- 退出账号或切换账号时清空筛选。
- 当前版本明确不实现多衣橱或“更换默认衣橱”，因此无需按衣橱维度保存筛选会话。
- `GarmentStore` 使用用户和衣橱作为数据 owner；账号切换时清空旧衣物，并以 generation 拒绝旧请求迟到写入，避免跨账号数据泄漏。
- 已打开的旧账号筛选弹窗会在账号变化时销毁，旧草稿不能写入新账号状态。
- 本期不使用数据库、`UserDefaults` 或远端配置持久化筛选条件。

### 2.5 Supabase 配置与真机构建修复

- 已修复“应用配置不可用，请检查本地 Supabase 配置”的启动页问题。
- `project.yml` 已改为使用 `Config/AppInfo.plist`，确保 `SUPABASE_URL` 和 `SUPABASE_PUBLISHABLE_KEY` 被打进应用包。
- 修复提交：`ab887d7 fix: include Supabase settings in app bundle`。
- 本地 `Config/Secrets.xcconfig` 已由用户补充真实值且被 Git 忽略；严禁把真实 URL/key 写入 Git、交接文档或聊天输出。
- 已恢复用户的 Personal Team 签名并成功完成真机构建、安装和启动。

## 3. 验证状态

- 最新相关 UI 回归：`WardrobeHomeTests + DesignSystemGalleryTests` 共 18 项，全部通过，0 失败。
- 新增/更新的 UI 测试覆盖：首页分类标签无数量、筛选弹窗无“分类”、筛选选项无数量、底部按钮布局、多维组合筛选。
- 用户已在真机完成视觉与交互验收，确认无误。
- 在最新 UI 修改之前，本分支曾完成完整测试：126 项单元测试 + 37 项 UI 测试，共 163 项，0 失败。
- 最新修改后的全量测试已启动，但用户确认改用真机验收后会话被中止，因此不要把这次全量运行记为完成；相关 18 项定向测试和真机验收均已通过。
- PR #4 的首次 CI 全量运行中，产品与单元测试正常，3 个 UI 断言因 CI 滚动误触和等待时间不足失败；测试流程修复后，两条涉及的测试已在本机重跑并通过（2 项，0 失败）。

## 4. 当前交付状态

- 功能提交：`b729487 feat: refine wardrobe filtering interface`。
- PR：`https://github.com/hyzgtihub/WardrobeAI/pull/4`，已合并。
- 本地 `main` 已同步到 PR #4 的合并提交。
- 当前仅剩 CI UI 稳定性修复和本交接更新需要提交并推送到 `main`。
- 功能工作树中的 `YISU.xcodeproj/project.pbxproj` 仍可能保留用户本地 Personal Team 差异；不要把个人签名推送到远程。

## 5. 当前卡住的问题

没有产品或功能层面的阻塞。

剩余的是 CI 收尾：提交 UI 测试稳定性修复并确认远程检查通过。功能本身没有阻塞。

## 6. 下一步计划

1. 提交并推送 UI 测试稳定性修复与本交接更新。
2. 确认 `main` 的远程 CI 通过；若仍有环境型 UI 波动，按失败日志继续收敛测试，不修改已验收的产品行为。
3. CI 收尾后关闭“分类浏览与组合筛选”周期。
4. 下一产品周期候选为“收藏持久化 + 智能集合”；开始编码前必须向用户确认入口、交互、集合范围和“当季”判定规则。

## 7. 踩过的坑与恢复方法

### 7.1 新 Swift 文件存在，但 Xcode 报类型不在作用域

- 原因：工程文件没有重新生成，新文件没有进入 target，而不是 Swift 类型本身写错。
- 处理：以 `project.yml` 为工程源，通过 XcodeGen 重新生成工程；不要长期手工维护 PBX 文件引用。
- 重新生成工程可能覆盖本地签名 Team，生成后必须检查 Signing & Capabilities。

### 7.2 Supabase 文件补了但应用仍提示配置不可用

- 仅创建 `Secrets.xcconfig` 不够，Info.plist 必须把构建变量映射为应用可读取的键。
- 当前正确链路：`Secrets.xcconfig` → Debug/Release xcconfig → `Config/AppInfo.plist` → 应用包。
- xcconfig 中 URL 的 `//` 会被当成注释；使用项目模板规定的转义写法，不要擅自改成普通 URL 文本。
- 修改配置后需要重新生成工程、清理旧构建产物并重新安装应用，旧安装包不会自动获得新配置。

### 7.3 删除 DerivedData 后依赖显示红色或首次构建失败

- 删除 `YISU-` 开头的 DerivedData 会让 Swift Package 重新解析和下载，Xcode 左侧依赖短暂标红并不等于源码损坏。
- 先等待 Resolve Package Graph 完成，再重新构建；不要反复删除缓存。

### 7.4 真机签名与工程再生成

- XcodeGen 重新生成可能移除用户选择的 Personal Team，导致 “Signing requires a development team”。
- 用户 Team ID 属于本地环境配置；保留本机可运行状态，但不要未经确认把个人签名信息作为产品代码提交。

### 7.5 UI 测试在长筛选弹窗中找不到底部维度

- 组合筛选测试曾因多个 DisclosureGroup 同时展开，导致底部“收纳位置”不可点击；XCUI 还会出现 Button/DisclosureTriangle 类型快照不一致。
- 测试 helper 已改为：必要时滚动查找，选择后折叠当前维度，再继续下一个维度。
- 该问题属于自动化可达性/滚动稳定性，不是筛选业务逻辑失败。
- iPhone SE 小屏对长弹窗更苛刻；当前主要定向回归使用 iPhone 17 Pro Max，真机视觉验收已通过。

### 7.6 不要误实现多衣橱清理逻辑

- 早期评审提出“更换默认衣橱时清空筛选”，但用户明确当前版本不实现多衣橱或更换衣橱。
- 当前只需保证账号切换时清空状态，不要为了未进入范围的场景扩展会话模型。

## 8. 主要提交

- `26083f9 docs: plan wardrobe category filtering`
- `66a8233 feat: add wardrobe filtering policy`
- `3f5ce26 feat: add counted category browser`
- `07dd9de feat: add wardrobe filter sheet`
- `6578d28 fix: expose active wardrobe filter state`
- `6d76f08 feat: integrate wardrobe filtering`
- `caf320a fix: isolate wardrobe sessions`
- `2796611 test: cover wardrobe filtering flows`
- `97634ac fix: preserve wardrobe filter action identifiers`
- `8086931 fix: preserve design system category identifiers`
- `e776972 fix: finalize wardrobe filtering handoff`
- `ab887d7 fix: include Supabase settings in app bundle`

## 9. 关键文件

- 工程源：`project.yml`
- 应用 Info.plist：`Config/AppInfo.plist`
- 本地密钥模板：`Config/Secrets.xcconfig.example`
- 本地真实密钥：`Config/Secrets.xcconfig`（Git 忽略，禁止提交）
- 纯筛选规则：`WardrobeApp/Features/Wardrobe/WardrobeFilter.swift`
- 首页集成：`WardrobeApp/Features/Wardrobe/WardrobeHomeView.swift`
- 分类浏览：`WardrobeApp/Features/Wardrobe/WardrobeCategoryBrowser.swift`
- 已生效条件栏：`WardrobeApp/Features/Wardrobe/WardrobeFilterBar.swift`
- 筛选弹窗：`WardrobeApp/Features/Wardrobe/WardrobeFilterSheet.swift`
- 会话接线：`WardrobeApp/App/RootView.swift`
- 衣物加载隔离：`WardrobeApp/Features/Wardrobe/GarmentStore.swift`
- 策略测试：`WardrobeAppTests/Wardrobe/WardrobeFilterPolicyTests.swift`
- 会话测试：`WardrobeAppTests/Wardrobe/GarmentStoreTests.swift`、`WardrobeAppTests/Wardrobe/WardrobeHomePolicyTests.swift`
- UI 测试：`WardrobeAppUITests/WardrobeHomeTests.swift`

## 10. 明确延期

- 文本搜索框、独立搜索页和本地关键字搜索。
- 多衣橱、切换默认衣橱及衣橱级筛选状态。
- 收藏字段持久化、卡片/详情收藏入口。
- 智能集合：最近添加、最爱、当季衣物。
- 服务端筛选、筛选偏好同步、价格和购买日期筛选。
- AI 图片处理、搭配、OOTD 和分享。
