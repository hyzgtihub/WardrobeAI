# YISU Gate A High-Fidelity UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有 Figma 文件中完成 Gate A 范围的 Light Mode 高保真 UI、组件体系、可点击原型和 SwiftUI 可开发交付物，并按 B1–B6 逐批获得用户验收。

**Architecture:** 现有 `04 Wireframes` 和 `05 Prototype` 保持为已验收历史基线；新增独立的 `06 Hi-Fi Exploration`、`07 Hi-Fi Screens`、`08 Hi-Fi Prototype` 与 `09 Dev Handoff` 页面。先以 P01、P05、P09 建立视觉方向，经 B1 确认后再固化变量和组件，随后按账户、衣橱浏览、衣物管理三个批次扩展，并在每个确认门后更新本地状态台账和项目交付管理包。

**Tech Stack:** Figma Design、Figma Plugin API、Codex Figma connector、iOS HIG、SF Pro、SwiftUI Design Token、Markdown、XLSX 项目交付管理包。

## Global Constraints

- Figma file key：`UMn1NvC2IUOA4xlXpLETRL`。
- 设计规格：`docs/superpowers/specs/2026-08-13-yisu-gate-a-high-fidelity-ui-design.md`。
- 周期基线：`outputs/project-delivery-management/衣序YISU-项目交付管理包-iOS原生基线-20260722.xlsx`。
- 本阶段仅做 Light Mode，认证方式仅为邮箱 + 密码，角色仅为默认角色“我”。
- 不加入微信、手机号、Sign in with Apple、宝宝或其他角色、AI 搭配、正式搭配功能、社区、支付和 Dark Mode。
- 使用 iOS 原生安全区域、SF Pro 系统字体和 44×44 pt 最小关键点击区域原则。
- 已验收的低保真页面和原型不覆盖、不删除；高保真内容写入新页面。
- 所有 Figma 写入均记录节点 ID，并同步到 `.codex-tmp/yisu-figma-phase2-state.json`。
- 每个 Gate 只有在用户明确确认后才标记通过并进入下一任务。
- 项目周期或范围发生变化时，必须同步更新项目交付管理包。

---

### Task 1: 启动高保真阶段并建立隔离结构

**Files:**
- Read: `docs/superpowers/specs/2026-08-13-yisu-gate-a-high-fidelity-ui-design.md`
- Read: `.codex-tmp/yisu-figma-phase1-state.json`
- Create: `.codex-tmp/yisu-figma-phase2-state.json`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`

**Interfaces:**
- Consumes: Phase 1 页面、变量、样式、组件和原型节点 ID；已确认的方案 A 范围。
- Produces: Phase 2 页面 ID、基线审计结果、B1–B6 状态结构和后续任务使用的节点映射。

- [ ] **Step 1:** 读取 Figma 当前页面、变量、样式、组件和 `05 Prototype` 顶层画面；断言 Phase 1 仍为 39 个顶层画面、100 条 NODE 跳转、失效目标 0。
- [ ] **Step 2:** 创建 `06 Hi-Fi Exploration`、`07 Hi-Fi Screens`、`08 Hi-Fi Prototype`、`09 Dev Handoff` 页面；若页面已存在则复用且不得创建重名页面。
- [ ] **Step 3:** 在 `06 Hi-Fi Exploration` 建立 B1 说明区，写明视觉原则、范围排除项和 P01/P05/P09 三张样稿的验收条件。
- [ ] **Step 4:** 创建 `.codex-tmp/yisu-figma-phase2-state.json`，至少记录 `fileKey`、四个新页面 ID、源页面 ID、Gate 状态、节点映射和 `pendingValidations`。
- [ ] **Step 5:** 截取四个新页面的结构截图，检查无重复页面、无覆盖低保真历史、无范围外功能。
- [ ] **Step 6:** 在 README 追加“高保真阶段已启动，当前 Gate B1”，并记录四个新页面链接。

### Task 2: Gate B1 三张视觉方向样稿

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`

**Interfaces:**
- Consumes: P01 默认、P05 有数据、P09 正常的已验收结构与文案；现有鼠尾草色、暖白和 SF Pro 基线。
- Produces: `B1/P01 登录`、`B1/P05 衣橱首页`、`B1/P09 衣物详情` 三个高保真样稿及视觉说明。

- [ ] **Step 1:** 在 `06 Hi-Fi Exploration` 复制 P01 默认页面结构，升级为高保真：暖白背景、品牌标识、邮箱与密码输入、主按钮、注册/忘记密码入口、默认勾选协议；不改变原交互含义。
- [ ] **Step 2:** 复制 P05 有数据页面结构，升级衣物图片卡、八分类横向标签、搜索入口、默认角色“我”和衣橱/搭配/我的三栏导航；卡片名称和第二行元数据均需完整可读。
- [ ] **Step 3:** 复制 P09 正常页面结构，升级大图、信息标签、重要信息/其他信息分组、返回衣橱与编辑入口；维持现有字段和值。
- [ ] **Step 4:** 在三张样稿旁建立“视觉语言说明”，逐项列出背景、主色、中性色、字体层级、圆角、阴影、图片比例、图标和主次操作规则。
- [ ] **Step 5:** 对三张样稿执行视觉审计：iPhone 安全区域正确、文本无截断、关键点击区域不小于 44×44 pt、相同语义采用相同样式。
- [ ] **Step 6:** 截取三张样稿的独立截图和并排截图，提交用户确认 Gate B1；暂停后续任务，直到用户明确确认或提出修改。
- [x] **Step 7:** 将用户选定的 `V3B · 柔焦衣间` 更新为候选定稿：问候语使用 `你好，Mia` 演示动态昵称；底部导航改为 `衣橱｜添加衣物｜我的`，中间使用 `60×60 pt` 的圆形加号主操作。
- [x] **Step 8:** 审计 V3B 的文字越界、图片数量、导航触控区与主操作辨识度，并将“图标质感与语义优化”登记为 Gate B2 输入项。
- [x] **Step 9:** 用户确认 P05 的 V3B 当前效果；在 Figma 评审板中标记为 P05 已确认的主视觉方向。
- [x] **Step 10:** 按 V3B 语言重制 P01 登录并提交用户确认，覆盖默认、协议未勾选和按钮禁用的视觉规则；用户于 2026-08-14 确认 P01。
- [x] **Step 10a:** 修正 P01 基础质量：品牌圆标文字几何居中；密码显示文字替换为 `44×44 pt` 眼睛图标控件；登录卡片采用精确 `24 pt` 的密码框→按钮、按钮→卡片底部、卡片→辅助链接间距。
- [x] **Step 10b:** 将“高保真页面完稿检查规范”写入规格，后续 P09 及全部页面必须在提交确认前执行十项审计。
- [ ] **Step 11:** 按 V3B 语言重制 P09 衣物详情并提交用户确认，覆盖真实衣物大图、直接编辑、自动保存、换图、更多操作与返回入口。
- [x] **Step 11a:** 完成 P09 V3B 候选稿节点 `220:2`，包含真实衣物主图、分类与季节标签、重要信息、其他信息和纵向滚动布局，并执行十项完稿检查。
- [x] **Step 11b:** 删除 P09 两张信息卡的标题与二级标题，仅保留卡片分组；新增完整内容开发视图节点 `232:2`，确保普通画布无需演示即可查看全部字段。
- [x] **Step 11c:** 比对滚动原型与完整内容开发视图：字段文本条目各 22，差异 0，横向越界 0，遗留标题 0。
- [x] **Step 11d:** 根据产品流程修订创建 P09 V3B v3：移除编辑/保存按钮，增加名称与 11 个字段的直接编辑入口、主图换图入口、自动保存四状态，并同步完整开发视图与状态评审板。
- [x] **Step 11e:** 执行 v3 十项检查：横向文字越界 0、缺失字段 0、低于 44 pt 的交互入口 0、字体不一致 0、占位文案 0；节点 `282:2`、`282:84`、`282:166`。
- [ ] **Step 12:** 将 P01、P05、P09 并排展示，补充配色、字体、圆角、阴影、图片和操作层级的一致性说明；用户确认后才将 Gate B1 标记为通过。
- [ ] **Step 7:** 用户确认后，将 `gateB1.status` 设为 `accepted`，记录日期、最终节点 ID 和用户确认摘要；README 和交付管理包中的 S2-01 更新为已验收、完成度 100%。

### Task 3: Gate B2 Foundations 与通用组件体系

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`

**Interfaces:**
- Consumes: Gate B1 获准的视觉语言和现有 Phase 1 变量/组件 ID。
- Produces: 高保真颜色、字体、间距、圆角、阴影、图标、图片规则及完整组件状态集合。

- [ ] **Step 1:** 将 B1 最终值固化到变量与样式；保留现有语义命名并补充高保真所需 Token，不创建同义重复 Token。
- [ ] **Step 2:** 在 `02 Foundations` 增补高保真规范区：颜色用途、SF Pro 字体层级、8 pt 间距体系、圆角、阴影、栅格、安全区域、图标尺寸和衣物图片裁切规则。
- [ ] **Step 3:** 升级 `YISU/Button`、`YISU/Form Field`、`YISU/Category Chip`、`YISU/Garment Card`，覆盖默认、按下、选中、禁用、加载、聚焦和错误中的实际适用状态。
- [ ] **Step 4:** 新增或升级 Navigation Bar、Bottom Tab Bar、Checkbox、Selection Row、Tag、Empty State、Error State、Loading Skeleton、Toast、Alert、Action Sheet 和 Photo Upload 组件。
- [ ] **Step 5:** 检查所有高保真组件实例的变量绑定、Auto Layout、文本伸缩、最小点击区域和状态命名；禁止以脱离组件的复制图层替代组件实例。
- [ ] **Step 6:** 在 `09 Dev Handoff` 建立 SwiftUI Token 对照表，逐项记录 Figma Token 名、语义、Swift 属性名和值或用法。
- [ ] **Step 7:** 提交 Foundations、核心组件和 Token 对照截图给用户确认 Gate B2；暂停后续任务直到明确确认。
- [ ] **Step 8:** 用户确认后，将 `gateB2.status` 设为 `accepted`，更新 S2-02 为已验收、完成度 100%。

### Task 4: Gate B3 账户、协议与初始化高保真页面

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`

**Interfaces:**
- Consumes: Gate B2 变量和组件；P01–P04 与 P13–P16 的已确认文案、状态和跳转规则。
- Produces: `07 Hi-Fi Screens` 中账户与初始化全状态页面及账户批次原型。

- [ ] **Step 1:** 完成 P01 登录的默认、输入中、校验失败、登录中、认证失败和协议未勾选状态。
- [ ] **Step 2:** 完成 P02 注册的默认、密码不符合、邮箱已存在、提交中、服务失败和协议未勾选状态。
- [ ] **Step 3:** 完成忘记密码、邮件已发送、设置新密码、服务条款和隐私政策高保真页面；忘记密码只采用邮箱重置链接。
- [ ] **Step 4:** 完成默认角色“我”的创建中、创建失败、成功跳转，以及当前角色、加载和失败状态；不出现新增、编辑或切换角色入口。
- [ ] **Step 5:** 为输入页面增加键盘评审状态或键盘占位图，检查当前输入框、错误信息和主操作不被遮挡。
- [ ] **Step 6:** 在 `08 Hi-Fi Prototype` 连接注册、登录、协议、密码重置和初始化流程；逐一验证返回、关闭、重试和成功目标。
- [ ] **Step 7:** 执行账户批次状态审计和死链审计，提交关键页面与流程截图给用户确认 Gate B3；暂停后续任务。
- [ ] **Step 8:** 用户确认后，将 `gateB3.status` 设为 `accepted`，更新 S2-03 为已验收、完成度 100%。

### Task 5: Gate B4 衣橱浏览、筛选、搜索与主导航

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`

**Interfaces:**
- Consumes: Gate B2 组件；P05、P06、搭配暂未开放和我的基础页的已确认结构与跳转。
- Produces: 衣橱浏览全状态页面和三栏导航高保真流程。

- [ ] **Step 1:** 完成 P05 加载、空白、有数据、筛选上衣和加载失败状态，统一使用高保真 Garment Card、Category Chip 和 Bottom Tab Bar。
- [ ] **Step 2:** 确认分类顺序为全部、上衣、裤子、外套、裙子、鞋子、配饰、其他；选中分类后，下方卡片内容与结果数一致。
- [ ] **Step 3:** 完成 P06 输入中、有结果、无结果和清空条件状态；搜索取消始终返回衣橱首页。
- [ ] **Step 4:** 完成搭配暂未开放和我的基础页；三栏导航只在三个主入口页面显示，衣橱进入时默认选中。
- [ ] **Step 5:** 对卡片执行长名称和第二行元数据检查，保证不遮挡、不与下一行卡片重叠；定义截断行数和最小卡片高度。
- [ ] **Step 6:** 在 `08 Hi-Fi Prototype` 连接衣橱、搜索、分类、搭配和我的流程，并审计每个返回和取消目标。
- [ ] **Step 7:** 提交衣橱首页五状态、搜索状态和三栏导航截图给用户确认 Gate B4；暂停后续任务。
- [ ] **Step 8:** 用户确认后，将 `gateB4.status` 设为 `accepted`，更新 S2-04 为已验收、完成度 100%。

### Task 6: Gate B5 照片、添加、详情、编辑与删除

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`

**Interfaces:**
- Consumes: Gate B2 组件；P07–P11 的字段、状态和入口感知返回规则。
- Produces: 衣物录入与管理全状态页面及完整 CRUD 高保真流程。

- [ ] **Step 1:** 完成照片选择器、已选择和重新选择状态，保证“添加”在选中照片后可见；Home Indicator 使用系统位置或在评审占位图中居中。
- [ ] **Step 2:** 完成 P08 默认、校验失败、保存中和保存失败；重要信息依次为图片、名称、分类、季节、收纳位置、备注，其他字段置于次要信息层。
- [ ] **Step 3:** 完成所有字段选择面板：分类单选、季节多选、颜色多选、收纳位置逐级单选、尺码按分类切换、购买日期原生选择、材质多选和风格多选。
- [ ] **Step 4:** 核对字段规则：季节全选显示“四季”；价格非必填、人民币元、仅不小于 0 的数字且最多两位小数；收纳位置仅该字段每一级均非必填；材质统一写“腈纶”。
- [ ] **Step 5:** 完成 P09 正常、加载、失败；完成 P10 未修改、已修改、保存中、保存失败、放弃更改确认和重新上传照片入口。
- [ ] **Step 6:** 完成 P11 更多操作、删除确认、删除中和删除失败；危险操作使用稳定的破坏性语义样式。
- [ ] **Step 7:** 在 `08 Hi-Fi Prototype` 分别连接“首页新增照片”和“编辑重新上传照片”两条入口；照片取消返回各自原始起点，编辑取消返回衣物详情，详情返回衣橱首页。
- [ ] **Step 8:** 执行字段、状态、返回目标和死链审计，提交 P07–P11 关键截图和流程给用户确认 Gate B5；暂停后续任务。
- [ ] **Step 9:** 用户确认后，将 `gateB5.status` 设为 `accepted`，更新 S2-05 为已验收、完成度 100%。

### Task 7: Gate B6 全局状态、完整原型与开发交付

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`
- Modify: `outputs/project-delivery-management/衣序YISU-项目交付管理包-iOS原生基线-20260722.xlsx`

**Interfaces:**
- Consumes: Gate B1–B5 已确认页面、组件、变量和原型节点。
- Produces: 完整高保真原型、QA 证据、开发交付页和阶段验收归档。

- [ ] **Step 1:** 完成 P12 成功提示、网络状态和可重试错误高保真状态，并将 Toast、Banner、Alert 和页面级错误限定到各自适用场景。
- [ ] **Step 2:** 将账户、初始化、衣橱、添加、搜索、详情、编辑、换图、删除、密码重置和协议流程连接到 `08 Hi-Fi Prototype`，设置明确原型起点。
- [ ] **Step 3:** 运行结构审计：统计顶层页面、组件实例、NODE 跳转、BACK 动作、缺失目标和无入口页面；失效目标必须为 0。
- [ ] **Step 4:** 运行视觉审计：逐页检查对齐、间距、文字截断、图片裁切、键盘、安全区域、Home Indicator、颜色对比度和 44×44 pt 关键点击区域。
- [ ] **Step 5:** 运行状态审计：对照规格逐项核对正常、加载、空白、无结果、校验失败、禁用、保存中、删除失败、网络异常和重试。
- [ ] **Step 6:** 完成 `09 Dev Handoff`：页面索引、组件索引、SwiftUI Token 对照、尺寸与间距、图片导出规则、图标来源、资源命名和开发注意事项。
- [ ] **Step 7:** 截取最终页面、组件、全流程和开发交付证据，提交用户进行 Gate B6 最终视觉验收；未确认前不标记阶段完成。
- [ ] **Step 8:** 用户确认后，将 `gateB6.status` 和阶段状态设为 `accepted`，记录最终审计指标；README 写入验收结论。
- [ ] **Step 9:** 更新项目交付管理包：S2-06 设为已验收、完成度 100%，Gate B-UI 设为已完成/Go，追加最终决策和证据位置，并扫描公式错误、渲染复核所有工作表。
- [ ] **Step 10:** 归档本地状态台账、最终 Figma 链接、开发交付清单和阶段结论；下一阶段必须由用户另行确认后启动。

## Execution Order and Review Gates

严格执行顺序：Task 1 → Task 2 / Gate B1 → Task 3 / Gate B2 → Task 4 / Gate B3 → Task 5 / Gate B4 → Task 6 / Gate B5 → Task 7 / Gate B6。

每个 Gate 提交时必须同时提供：

1. 本批次页面或组件清单。
2. 关键截图或 Figma 节点链接。
3. 与验收标准逐项对应的检查结果。
4. 已知限制和范围外事项。
5. 明确的“请确认/请修改”结论。

用户未明确确认时，不进入下一 Gate。
