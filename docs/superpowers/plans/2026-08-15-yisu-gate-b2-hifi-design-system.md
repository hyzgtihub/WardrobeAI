# YISU Gate B2 High-Fidelity Design System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不修改低保真历史资产的前提下，创建独立的衣序高保真 Figma Foundations、组件库、`DESIGN.md`、机器可读 `tokens.json` 和 SwiftUI Token 对照，并提交 Gate B2 用户验收。

**Architecture:** 现有 `02 Foundations` 与 `03 Components` 保持只读历史基线；新增 `06A Hi-Fi Foundations` 与 `06B Hi-Fi Components` 页面，并创建以 `YISU Hi-Fi` 命名的独立变量、样式和组件。`tokens.json` 作为机器可读数据源，`DESIGN.md` 解释使用规则，Figma 负责视觉与组件事实，三者通过名称和值审计保持一致。

**Tech Stack:** Figma Design、Figma Plugin API、Codex Figma connector、DTCG-style JSON、Markdown、Node.js JSON validation、SF Pro Rounded、SF Symbols、SwiftUI Design Token。

## Global Constraints

- Figma file key：`UMn1NvC2IUOA4xlXpLETRL`。
- 设计规格：`docs/superpowers/specs/2026-08-15-yisu-gate-b2-hifi-design-system-design.md`。
- 当前隔离工作区：`.worktrees/codex-yisu-inline-autosave`，分支 `codex/yisu-inline-autosave`。
- 不修改或删除 `02 Foundations`、`03 Components` 及其低保真变量、样式和组件。
- 新增页面固定命名为 `06A Hi-Fi Foundations`、`06B Hi-Fi Components`。
- 新变量集合固定命名为 `YISU Hi-Fi / Primitives`、`YISU Hi-Fi / Semantic Colors`、`YISU Hi-Fi / Layout`。
- 高保真样式与组件统一使用 `YISU Hi-Fi/` 前缀。
- 本阶段仅支持 Light Mode；不创建 Dark Mode。
- 正式高保真字体为 `SF Pro Rounded`；系统数据或平台控件可使用 `SF Pro`。
- 主要操作和独立图标按钮的触控区域不得小于 `44×44 pt`。
- Figma 写操作严格串行；每次创建后返回节点 ID 并写入 `.codex-tmp/yisu-figma-phase2-state.json`。
- 用户明确确认 Gate B2 前，不开始 Gate B3，不把 Gate B2 或 S2-02 标记为完成。
- 项目周期变化时，以 `outputs/project-delivery-management/衣序YISU-项目交付管理包-iOS原生基线-20260722.xlsx` 为唯一周期基线。

---

### Task 1: 建立机器可读 Token 源与校验器

**Files:**
- Create: `figma-deliverables/衣序YISU-GateA原型与UI设计/tokens.json`
- Create: `figma-deliverables/衣序YISU-GateA原型与UI设计/scripts/validate-design-tokens.mjs`
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`

**Interfaces:**
- Consumes: Gate B1 V3B 颜色方向、8pt 栅格、SF Pro Rounded 字体、44pt 触控规则。
- Produces: `tokens.json`，字段结构为 `{ color, spacing, radius, size, typography, shadow, motion }`；验证脚本退出码 `0` 表示语法、引用和必填扩展均通过。

- [ ] **Step 1:** 创建 `tokens.json`，所有叶节点均包含 `$type`、`$value`、`description` 和 `extensions.swiftUI`；语义色使用 `{color.primitive.*}` 引用，不复制 Hex。
- [ ] **Step 2:** 录入 V3B 原始颜色：奶油白、暖白、极淡米卡其、柔焦灰蓝、薰衣草紫、复古肉粉、鼠尾草绿、深灰紫黑，以及成功、警告、错误和遮罩必要颜色。
- [ ] **Step 3:** 录入语义色：canvas、surface、四种 garment tint、accent default/pressed/disabled、text primary/secondary/inverse、border default/focus/divider、icon primary/accent、status success/warning/error、overlay。
- [ ] **Step 4:** 录入间距 `4、8、12、16、20、24、32、40、48、64`，圆角 `8、12、16、20、24、32、999`，尺寸 `44、48、56、60、84`。
- [ ] **Step 5:** 录入 Display、Large Title、Title 1、Title 2、Headline、Body、Callout、Subheadline、Footnote、Caption 字体 Token，以及 Subtle、Card、Floating 阴影 Token。
- [ ] **Step 6:** 创建 `validate-design-tokens.mjs`：解析 JSON；递归检查叶节点字段；解析花括号引用；确认引用目标存在；确认所有 Token 有 `extensions.swiftUI`；打印分类计数和错误列表。
- [ ] **Step 7:** 运行 `node figma-deliverables/衣序YISU-GateA原型与UI设计/scripts/validate-design-tokens.mjs`；预期输出 `PASS`、引用错误 `0`、缺失 SwiftUI 映射 `0`。
- [ ] **Step 8:** 更新 Phase 2 状态台账，记录 Token 文件、验证命令、分类计数和 `tokensValidation.status = passed`。
- [ ] **Step 9:** 仅提交本任务文件，提交信息：`design: add Gate B2 machine-readable tokens`。

### Task 2: 创建 `DESIGN.md` 设计契约

**Files:**
- Create: `figma-deliverables/衣序YISU-GateA原型与UI设计/DESIGN.md`
- Create: `figma-deliverables/衣序YISU-GateA原型与UI设计/scripts/validate-design-doc.mjs`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`

**Interfaces:**
- Consumes: `tokens.json` 的正式 Token 路径和值。
- Produces: AI、设计和开发共同遵守的 `DESIGN.md`；文档校验器确认必需章节与 Token 引用完整。

- [ ] **Step 1:** 创建 `DESIGN.md`，写明品牌原则、适用范围、低/高保真隔离、唯一视觉方向 V3B 和范围外功能。
- [ ] **Step 2:** 写入颜色、字体、间距、圆角、阴影、图标、图片、触控与无障碍规范；所有示例使用 `tokens.json` 的实际 Token 路径。
- [ ] **Step 3:** 写入 16 个组件的用途、属性、适用状态、禁止用法和最小尺寸。
- [ ] **Step 4:** 写入 Figma → JSON → SwiftUI 映射规则、AI 使用前置步骤、变更与废弃流程。
- [ ] **Step 5:** 创建 `validate-design-doc.mjs`，检查必需章节、`tokens.json` 链接、16 个组件名称及禁止占位符 `TBD|TODO|待补充`。
- [ ] **Step 6:** 运行 `node .../validate-design-doc.mjs`；预期输出 `PASS`、缺失章节 `0`、缺失组件 `0`、占位符 `0`。
- [ ] **Step 7:** README 增加 Gate B2 设计系统入口、校验命令和“低保真资产不修改”声明。
- [ ] **Step 8:** 提交本任务文件，提交信息：`docs: add YISU high-fidelity design contract`。

### Task 3: 创建独立 Figma 页面与高保真变量集合

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Read: `figma-deliverables/衣序YISU-GateA原型与UI设计/tokens.json`

**Interfaces:**
- Consumes: `tokens.json` 的颜色、间距、圆角和尺寸 Token。
- Produces: 两个新页面 ID、三个变量集合 ID、全部变量 ID 与变量审计结果。

- [ ] **Step 1:** 读取 Figma 页面、变量集合和状态台账，断言目标页面和集合尚不存在；若存在则按台账 ID 复用，不创建重名对象。
- [ ] **Step 2:** 创建 `06A Hi-Fi Foundations` 页面，返回页面 ID 并立即写入状态台账。
- [ ] **Step 3:** 创建 `06B Hi-Fi Components` 页面，返回页面 ID 并立即写入状态台账。
- [ ] **Step 4:** 创建 `YISU Hi-Fi / Primitives` 集合和 `Value` 模式；按 `tokens.json` 创建原始变量，设置 Scope `[]`、iOS Code Syntax 和描述。
- [ ] **Step 5:** 创建 `YISU Hi-Fi / Semantic Colors` 集合和 `Light` 模式；创建语义变量并通过 Variable Alias 指向高保真原始变量；设置明确 Scope 与 iOS Code Syntax。
- [ ] **Step 6:** 创建 `YISU Hi-Fi / Layout` 集合和 `Value` 模式；创建间距、圆角和尺寸变量，分别设置 `GAP`、`CORNER_RADIUS`、`WIDTH_HEIGHT` 等适用 Scope 与 iOS Code Syntax。
- [ ] **Step 7:** 运行变量审计：集合数量 `3`；模式分别为 `Value/Light/Value`；变量数量等于 `tokens.json` 可映射变量数；`ALL_SCOPES` 数量 `0`；缺失 iOS Code Syntax 数量 `0`；断裂 Alias 数量 `0`。
- [ ] **Step 8:** 核对低保真集合仍为 `Primitives`、`Color`、`Spacing & Radius`，ID 和变量数量未改变。
- [ ] **Step 9:** 更新状态台账，记录集合、变量、审计结果和 `P1.variables = passed`。

### Task 4: 创建高保真文字与效果样式

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Read: `figma-deliverables/衣序YISU-GateA原型与UI设计/tokens.json`

**Interfaces:**
- Consumes: typography 与 shadow Token。
- Produces: `YISU Hi-Fi/Typography/*` 文字样式和 `YISU Hi-Fi/Shadow/*` 效果样式。

- [ ] **Step 1:** 使用 `listAvailableFontsAsync()` 确认 `SF Pro Rounded` 的 Regular、Medium、Semibold、Bold 样式可用；缺失任一必需字体时停止并报告。
- [ ] **Step 2:** 创建 10 个高保真文字样式，逐项设置字体、字号、行高、字间距和描述；不得修改现有 `iOS/*` 文字样式。
- [ ] **Step 3:** 创建 Subtle、Card、Floating 三个高保真效果样式；不得修改现有 `YISU/Shadow/Subtle`。
- [ ] **Step 4:** 审计样式名称、数量和值与 `tokens.json` 完全一致；重复名称 `0`，字体替代 `0`。
- [ ] **Step 5:** 更新状态台账，记录样式 ID 和 `P1.styles = passed`。

### Task 5: 构建 `06A Hi-Fi Foundations` 文档页

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Read: `figma-deliverables/衣序YISU-GateA原型与UI设计/DESIGN.md`

**Interfaces:**
- Consumes: Task 3 的变量和 Task 4 的样式。
- Produces: 可视化 Foundations 根节点、分区节点和验收截图。

- [ ] **Step 1:** 创建 Foundations 页面根容器，采用 Auto Layout，标题标明 `Gate B2 · YISU Hi-Fi Design System` 和版本 `v1.0`。
- [ ] **Step 2:** 创建颜色区：原始色、语义色、衣物柔焦背景和状态色；所有色块绑定高保真变量。
- [ ] **Step 3:** 创建字体区：展示 10 个文字样式及中文样例、字号、字重、行高和 SwiftUI 名称。
- [ ] **Step 4:** 创建间距、圆角、尺寸和阴影区；示例绑定变量或样式，标注用途而非只展示数值。
- [ ] **Step 5:** 创建栅格、安全区域、图标、图片和无障碍规则区，包含 44pt 触控、SF Symbols 名称和衣物抠图示例。
- [ ] **Step 6:** 截图并检查文本截断、硬编码色块、字体不一致和边界溢出；四项失败数量均为 `0`。
- [ ] **Step 7:** 更新状态台账，记录根节点、分区节点、截图和 `P2.foundationsDocs = passed`。

### Task 6: 构建表单与选择类核心组件

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`

**Interfaces:**
- Consumes: 高保真变量、文字样式和效果样式。
- Produces: `YISU Hi-Fi/Button`、`Form Field`、`Checkbox`、`Category Chip`、`Tag`、`Selection Row` 组件集。

- [ ] **Step 1:** 创建 Button：Primary/Secondary/Destructive × Default/Pressed/Disabled/Loading，限制变体总数并提供文本属性。
- [ ] **Step 2:** 创建 Form Field：Text/Secure × Default/Focused/Filled/Error/Disabled，并提供 Label、Value、Helper 和图标属性。
- [ ] **Step 3:** 创建 Checkbox：Checked/Unchecked × Default/Pressed/Disabled，独立触控容器为 44×44pt。
- [ ] **Step 4:** 创建 Category Chip：Default/Selected/Pressed/Disabled；创建 Tag：Default/Accent/Success/Error。
- [ ] **Step 5:** 创建 Selection Row：Default/Pressed/Disabled/Error，支持 Label、Value、Required、Chevron。
- [ ] **Step 6:** 对每个组件逐一运行结构与视觉审计：Auto Layout、变量绑定、44pt、长中文、组件属性、变体名称均通过；每个组件单独截图。
- [ ] **Step 7:** 更新状态台账并记录六组组件 ID 与验证结果。

### Task 7: 构建导航、内容与反馈组件

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`

**Interfaces:**
- Consumes: Task 6 已验证的原子组件和全部高保真 Token。
- Produces: Navigation Bar、Bottom Tab Bar、Garment Card、Photo Upload、Empty State、Error State、Loading Skeleton、Toast、Alert、Action Sheet。

- [ ] **Step 1:** 创建 Navigation Bar，支持 Back/Cancel/None 前导、标题和 Text/Icon/More 尾部操作，所有图标采用 SF Symbols 名称。
- [ ] **Step 2:** 创建 Bottom Tab Bar，固定业务结构 `衣橱｜添加衣物｜我的`；中央添加按钮 60×60pt，其他项目触控区不小于 44pt。
- [ ] **Step 3:** 创建 Garment Card，支持四种柔焦背景、Default/Pressed、真实衣物图、名称和元数据。
- [ ] **Step 4:** 创建 Photo Upload，覆盖 Empty/Selected/Uploading/Error，并提供 Change Photo 入口。
- [ ] **Step 5:** 创建 Empty State、Error State 和 Loading Skeleton 的实际业务变体。
- [ ] **Step 6:** 创建 Toast、Alert 和 Action Sheet，区分普通、成功、错误和破坏性语义。
- [ ] **Step 7:** 对每个组件逐一运行结构与视觉审计；检查 Auto Layout、变量绑定、触控尺寸、长中文、状态命名和截图。
- [ ] **Step 8:** 更新状态台账并记录十组组件 ID 与验证结果。

### Task 8: 建立 SwiftUI 对照与三页替换验证

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/DESIGN.md`

**Interfaces:**
- Consumes: Figma 变量、样式、组件与本地 `tokens.json`。
- Produces: `09 Dev Handoff` Token 对照、P01/P05/P09 验证副本和跨资产一致性报告。

- [ ] **Step 1:** 在 `09 Dev Handoff` 创建 Token 对照表，包含 Figma 名、JSON 路径、SwiftUI 名、类型和值/引用。
- [ ] **Step 2:** 创建组件索引，包含 Figma 组件 ID、SwiftUI 目标类型、属性和状态。
- [ ] **Step 3:** 复制已确认的 P01、P05、P09 为 Gate B2 验证副本；只替换样式与组件，不改变信息结构和交互含义。
- [ ] **Step 4:** 审计验证副本：低保真变量绑定 `0`、低保真组件实例 `0`、未绑定高保真颜色 `0`、文字样式不一致 `0`、触控不足 `0`、文本溢出 `0`。
- [ ] **Step 5:** 比对 Figma、`tokens.json`、`DESIGN.md` 和 SwiftUI 对照：缺失名称 `0`、值冲突 `0`、重复语义 `0`。
- [ ] **Step 6:** 更新 `DESIGN.md` 的最终节点索引和版本记录；运行两个本地校验器并确认均为 `PASS`。
- [ ] **Step 7:** 更新状态台账，记录 Dev Handoff、三页验证副本和跨资产审计结果。

### Task 9: 提交 Gate B2 验收

**Files:**
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Create: `figma-deliverables/衣序YISU-GateA原型与UI设计/evidence/2026-08-18-gate-b2/`

**Interfaces:**
- Consumes: Tasks 1–8 的全部通过结果。
- Produces: Gate B2 验收板、截图、用户确认请求；不提前关闭 Gate B2。

- [ ] **Step 1:** 创建 Gate B2 验收板，展示 Foundations、组件组、Token 对照、三页替换验证和后续专项。
- [ ] **Step 2:** 运行最终审计：变量 Scope、Code Syntax、Alias、样式、组件绑定、Auto Layout、触控尺寸、文本溢出、跨资产名称和值。
- [ ] **Step 3:** 将 Foundations、组件库、Dev Handoff、三页验证和验收板截图归档到 evidence 目录。
- [ ] **Step 4:** README 写入 Gate B2 提交内容、节点 ID、审计结果、已知限制和范围外事项。
- [ ] **Step 5:** 状态台账设置 `B2.status = awaiting_user_review`，不得设置为 `confirmed`。
- [ ] **Step 6:** 运行 `git diff --check`、两个本地校验器、JSON 语法检查和 Figma 最终只读审计。
- [ ] **Step 7:** 提交本地成果，提交信息：`design: submit Gate B2 high-fidelity system`。
- [ ] **Step 8:** 向用户提供页面/组件清单、关键截图、逐项验收结果、限制及明确的“请确认/请修改”结论；暂停等待用户确认。

## Self-Review Result

- 规格覆盖：隔离架构、Figma Foundations、16 个组件、`DESIGN.md`、`tokens.json`、SwiftUI 对照、审计和 Gate B2 确认均有对应任务。
- 占位符扫描：计划不包含待实现占位内容；每项均定义输入、输出和验收结果。
- 接口一致性：`tokens.json` 是本地值源；Figma 使用同名变量；`DESIGN.md` 解释同一 Token；Dev Handoff 映射同一 SwiftUI 名称。
- 范围边界：本计划只完成 Gate B2，不批量制作 Gate B3 页面，不修改低保真历史资产，不直接重构 SwiftUI 页面。
