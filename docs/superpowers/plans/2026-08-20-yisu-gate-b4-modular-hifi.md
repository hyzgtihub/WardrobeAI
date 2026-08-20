# 衣序 YISU Gate B4 模块化高保真实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 Gate B3 验收归档，并以复用 Gate B1 确认稿、构建状态组件和只制作三张新增关键整页的方式交付 Gate B4。

**Architecture:** Figma `06B` 先提供单一来源的模块化状态组件，`07` 页面只由确认稿副本和组件实例组成，`08` 只连接核心业务路径。Figma、阶段状态、README 与项目交付管理包使用同一验收状态和范围说明，Gate B4 完成后保持 `awaiting_user_review`。

**Tech Stack:** Figma Plugin API / `use_figma`、Figma variables and component sets、Markdown、JSON、`@oai/artifact-tool`、XLSX、Git isolated worktree

**Spec:** `docs/superpowers/specs/2026-08-20-yisu-gate-b4-modular-hifi-design.md`

## Global Constraints

- Figma 文件键固定为 `UMn1NvC2IUOA4xlXpLETRL`。
- 唯一视觉源为 Gate B1 确认板 `293:2` 中 P01 `294:5`、P05 `294:48`、P09 `294:100`；三页页面级 `stroke = 0`。
- P01、P05、P09不得重新设计；Gate B4 只复制 P05、P09并连接组件和原型。
- 新增关键整页只包括搜索、P08 添加衣物、P12 我的。
- 状态通过组件变体表达，不为 Empty、Loading、Error、No Results 或筛选分别复制整页。
- 所有高保真页面使用 `SF Pro Rounded`、`06A/06B v1.1` token 和不小于 `44×44 pt` 的触控区。
- 不制作 PhotosPicker 仿真整页、自定义键盘、搭配、AI、社区、支付、多角色、其他登录方式或 Dark Mode。
- Gate B3 写入 `accepted`；Gate B4 未经用户验收只能写入 `awaiting_user_review`。
- 项目周期变更只修改 `/Users/huyouzhen/Documents/衣橱APP/outputs/project-delivery-management/衣序YISU-项目交付管理包-iOS原生基线-20260722.xlsx`。

---

### Task 1: Gate B3 正式验收归档

**Files:**
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Verify: Figma `07 Hi-Fi Screens` board `477:124`

**Interfaces:**
- Consumes: Gate B3 用户验收结论、20 张高保真状态、08 原型 `26/26` 可达审计。
- Produces: `GateB3Archive = { status: "accepted", acceptedAt: "2026-08-20", reviewBoardId: "477:124" }`，供表格和 Gate B4 状态引用。

- [ ] **Step 1: 读取并验证 Gate B3 当前状态**

运行 Figma 只读审计，确认 `477:124` 下仍有 20 个 `390×844` 状态、外描边违规 0；确认 `08 Hi-Fi Prototype` 起点 `381:2` 仍可达 26/26 顶层原型屏且死链为 0。

- [ ] **Step 2: 在 Figma 标记验收**

在 `477:124` 的标题区增加或更新状态胶囊为 `GATE B3 · ACCEPTED · 2026-08-20`。只修改标题区，不移动、重绘或解除现有页面实例。

- [ ] **Step 3: 更新本地状态**

使用 `apply_patch` 将 `.codex-tmp/yisu-figma-phase2-state.json` 中 `gates.B3.status` 改为 `accepted`，增加 `acceptedAt: "2026-08-20"`；保持 B4 为 `pending` 直到 Task 3 开始。

- [ ] **Step 4: 更新 README**

使用 `apply_patch` 将 Gate B3 章节改为“验收通过”，写明 20 张状态、26/26 可达、死链 0 和验收日期；Gate B4 章节引用已确认的模块化规格。

- [ ] **Step 5: 验证归档**

运行：

```bash
python3 -m json.tool .codex-tmp/yisu-figma-phase2-state.json >/dev/null
git diff --check -- figma-deliverables/衣序YISU-GateA原型与UI设计/README.md
```

预期：两条命令退出码均为 0，Figma 状态胶囊文本与日期正确。

---

### Task 2: 同步项目交付管理包

**Files:**
- Modify: `/Users/huyouzhen/Documents/衣橱APP/outputs/project-delivery-management/衣序YISU-项目交付管理包-iOS原生基线-20260722.xlsx`
- Create: `.codex-tmp/gate-b4-workbook-update.mjs`

**Interfaces:**
- Consumes: Task 1 的 `GateB3Archive` 与 Gate B4 规格中的关键页面、组件和验收范围。
- Produces: `DeliveryScheduleUpdate`，明确 Gate B3 已完成、Gate B4 模块化执行中和范围缩减原因。

- [ ] **Step 1: 加载官方工作区依赖并读取表格指导**

调用 `load_workspace_dependencies`，使用返回的 Node 与 `@oai/artifact-tool` 路径；完整读取 spreadsheet API quick start 和样式规范。不得使用 `openpyxl`、`xlsxwriter` 或系统级替代库。

- [ ] **Step 2: 只读导入并检查工作簿**

导入基线文件，列出工作表、已用区域和包含 `Gate B3`、`Gate B4`、`Sprint`、`高保真` 的单元格。渲染受影响工作表，确认现有字体、颜色、边框、合并单元格和列宽基线。

- [ ] **Step 3: 编写定向更新脚本**

在 `.codex-tmp/gate-b4-workbook-update.mjs` 中：

```js
const gateB3 = {
  status: "已验收",
  completedAt: "2026-08-20",
  deliverable: "20 个模块化高保真状态；08 原型 26/26 可达，死链 0"
};
const gateB4 = {
  status: "进行中",
  scope: "复用 P05/P09；新增搜索、P08、P12；状态沉淀为组件",
  optimization: "不为每个状态复制整页，降低设计与开发重复成本"
};
```

脚本只更新现有阶段/任务/风险对应行；若工作簿已有变更记录表，则追加一行 `2026-08-20 / Gate B4 模块化范围确认`，继承相邻格式。

- [ ] **Step 4: 执行编辑并导出原路径**

先运行一次：

```bash
node container_tools/mark_artifact_operation_started.mjs --operation-kind edit --expected-output-count 1 --output-format xlsx
```

随后运行更新脚本，将结果保存回唯一基线文件路径，不创建名称相近的第二份周期管理包。

- [ ] **Step 5: 验证内容和视觉**

使用 `workbook.inspect` 检查更新范围的值与公式，扫描 `#REF!|#DIV/0!|#VALUE!|#NAME\?|#N/A`，渲染所有受影响工作表。预期：无公式错误、无关键文字裁切、原有格式未被全表重置。

---

### Task 3: 构建 Gate B4 模块化组件

**Files:**
- Modify: Figma `06B Hi-Fi Components` page `317:3`, root `333:2`
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Modify when new token is unavoidable: `figma-deliverables/衣序YISU-GateA原型与UI设计/tokens.json`
- Modify when component contract changes: `figma-deliverables/衣序YISU-GateA原型与UI设计/DESIGN.md`

**Interfaces:**
- Consumes: `06A/06B v1.1` variables、文字样式、现有 Button、Garment Card、Photo Hero、Editable Field Row、Bottom Navigation。
- Produces: `GateB4Components`，包含八个命名组件集和每个变体的节点 ID。

- [ ] **Step 1: 建立组件缺口清单**

一次性读取 `333:2` 的组件集、变体属性和变量绑定。按组件名匹配 Content State、Category Filter、Garment Card/Grid、Form Section/Field Row、Photo Hero、Auto-save Status、Confirm Dialog、Bottom Navigation；只创建缺失项，只补充缺失变体。

- [ ] **Step 2: 构建 Content State 与筛选组件**

创建或扩展：

```text
YISU Hi-Fi/Content State: Content | Empty | Loading | Error | No Results
YISU Hi-Fi/Category Chip: Default | Selected | Pressed | Disabled
YISU Hi-Fi/Category Filter: All | Tops | Pants | Outerwear | Dresses | Shoes | Accessories | Other
```

公开标题、说明、CTA 文案和状态属性；Loading 使用骨架层，Error 使用重试按钮实例。

- [ ] **Step 3: 构建衣物、表单与照片模块**

创建或扩展：

```text
YISU Hi-Fi/Garment Card: Default | Pressed | Loading | Image Error
YISU Hi-Fi/Garment Grid: Default
YISU Hi-Fi/Form Section: Important | Secondary
YISU Hi-Fi/Field Row: Text | Single | Multi | Date | Hierarchy | Number × Default | Focused | Filled | Error | Disabled
YISU Hi-Fi/Photo Hero: Empty | Loaded | Loading | Error
```

Garment Card 名称支持两行、元数据一行；Photo Hero 使用现有图片与按钮，不生成新图片。

- [ ] **Step 4: 构建自动保存、删除和底栏模块**

创建或扩展：

```text
YISU Hi-Fi/Auto-save Status: Idle | Saving | Saved | Error
YISU Hi-Fi/Confirm Dialog: Default | Deleting | Error
YISU Hi-Fi/Bottom Navigation: Wardrobe Selected | Profile Selected
```

禁用和加载中的危险操作不得有页面跳转；Error 变体提供重试，取消操作维持返回当前详情页。

- [ ] **Step 5: 建立 Gate B4 组件评审区**

在 `06B` 根板末尾追加 `Gate B4 · Modular States` 区域，按内容状态、浏览、表单/照片、反馈/导航四组排列实例。每个变体只展示一次，并在标题说明“用于页面内容替换，不复制整页”。

- [ ] **Step 6: 审计组件**

一次性检查组件集存在性、重复、变量绑定、字体、最小触控区和文本溢出。预期：8 组模块齐全；`SF Pro Rounded` 以外字体 0；小于 44pt 的独立操作 0；可见空文本和非预期溢出 0。

---

### Task 4: 创建 Gate B4 关键页面评审板

**Files:**
- Modify: Figma `07 Hi-Fi Screens` page `168:3`
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`

**Interfaces:**
- Consumes: Gate B1 P05 `294:48`、P09 `294:100` 和 Task 3 的 `GateB4Components`。
- Produces: `GateB4Screens`，包含 P05 副本、搜索、P08 原型视图、P08 完整高度视图、P09 副本、P12。

- [ ] **Step 1: 创建评审板与复用副本**

在 `07` 新建 `Gate B4 · Wardrobe Core · Modular Review`，复制 P05 `294:48` 和 P09 `294:100`。复制后验证根尺寸、所有文本、图片填充、页面外描边和主要子层几何与来源一致；差异数必须为 0。

- [ ] **Step 2: 创建搜索整页**

使用 Header、Category Filter、Garment Grid 和 Bottom Navigation 实例创建一张 `390×844` 搜索结果页。默认展示关键词“白”、选中“上衣”和 1 件结果；取消按钮为 `44×44 pt` 点击区，返回 P05。

- [ ] **Step 3: 创建 P08 添加衣物**

使用 Photo Hero、Form Section 和 Field Row 实例创建：

- `P08 添加衣物 · Prototype`：`390×844`，纵向滚动。
- `P08 添加衣物 · Full Content Handoff`：宽 390，完整显示全部字段。

字段依次为图片、名称、分类、季节、收纳位置、备注、颜色、品牌、价格、尺码、购买日期、材质、风格。名称、分类、季节为必填；价格规则为非负数字、最多两位小数、人民币元。

- [ ] **Step 4: 创建 P12 我的**

使用 Navigation Bar、内容卡片、Editable/Selection Row 和 Bottom Navigation 实例创建一张 `390×844` 页面，显示昵称 Mia、邮箱 `mia@example.com`、服务条款、隐私政策和退出登录。底栏使用 `Profile Selected`。

- [ ] **Step 5: 添加状态组件评审区**

在页面评审板右侧放置 Content State、分类筛选、Auto-save Status 和 Confirm Dialog 的实例矩阵；不得复制 P05/P08/P09/P12 来展示状态。

- [ ] **Step 6: 页面审计**

检查：P05/P09 来源差异 0；新增整页 3 张、P08 完整高度视图 1 张；页面外描边违规 0；分类八项齐全；独立点击区小于 44pt 为 0；非预期文字裁切为 0。

---

### Task 5: 连接 Gate B4 核心原型

**Files:**
- Modify: Figma `08 Hi-Fi Prototype` page `168:4`
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`

**Interfaces:**
- Consumes: Task 4 的 `GateB4Screens` 和 Task 3 的 Confirm Dialog、Auto-save Status 组件。
- Produces: `GateB4PrototypeGraph`，从 P05 出发覆盖搜索、添加、详情、删除和我的。

- [ ] **Step 1: 创建原型屏副本**

只克隆 P05、搜索、P08 原型视图、P09 和 P12；状态通过交互组件或覆盖层展示。P08 完整高度交付视图不进入原型。

- [ ] **Step 2: 连接浏览和搜索**

连接 `P05 搜索 → 搜索页 → 衣物结果 → P09`；搜索取消返回 P05。分类 Chip 使用同页面变体或内容替换，不创建独立顶层屏。

- [ ] **Step 3: 连接添加和照片规则**

连接 `P05 中央加号 → P08`。照片入口使用系统选择器说明覆盖层；取消关闭覆盖层并保持 P08，添加照片后回到 P08 Loaded 状态。

- [ ] **Step 4: 连接详情、自动保存和删除**

连接 `P05 衣物卡 → P09`。字段行触发保存状态组件；更多菜单打开删除确认覆盖层，取消关闭覆盖层，删除成功回 P05，删除失败切换 Error 变体并允许重试。

- [ ] **Step 5: 连接我的与退出**

连接 `P05 我的 → P12`；P12 的服务条款、隐私政策复用现有 P15/P16；退出登录打开确认组件，确认后回现有 P01，取消留在 P12。

- [ ] **Step 6: 原型图审计**

从 Gate B4 P05 起点执行可达图检查。预期：所有 Gate B4 顶层屏均可达；失效 NODE 目标 0；没有入边的非起点屏 0；禁用按钮 reaction 0；搜索取消、删除取消和照片取消均回到规格指定上下文。

---

### Task 6: 交付文档、证据与最终验证

**Files:**
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`
- Modify when component contract changed: `figma-deliverables/衣序YISU-GateA原型与UI设计/DESIGN.md`
- Modify when tokens changed: `figma-deliverables/衣序YISU-GateA原型与UI设计/tokens.json`
- Modify: `.codex-tmp/yisu-figma-phase2-state.json`
- Create: `evidence/2026-08-20-gate-b4-modular-hifi/`

**Interfaces:**
- Consumes: Tasks 1–5 的 Figma 节点、审计结果和工作簿更新。
- Produces: 可复核的 Gate B4 `awaiting_user_review` 交付包与本地提交。

- [ ] **Step 1: 更新状态与说明**

README 记录组件策略、关键页面、来源副本和原型审计；状态文件记录组件集 ID、页面 ID、原型起点和 `gates.B4.status = "awaiting_user_review"`。只有新增 token 时才提升 `tokens.json` 补丁版本，并同步 DESIGN.md。

- [ ] **Step 2: 保存精简证据**

只保存以下 PNG：Gate B3 Accepted 标题、Gate B4 组件评审区、Gate B4 关键页面整板、P08 完整高度视图、Gate B4 原型关键路径。使用 `file` 验证 PNG 有效，不逐屏导出等价状态。

- [ ] **Step 3: 运行本地校验**

运行：

```bash
node figma-deliverables/衣序YISU-GateA原型与UI设计/scripts/validate-design-tokens.mjs
node figma-deliverables/衣序YISU-GateA原型与UI设计/scripts/validate-design-doc.mjs
python3 -m json.tool .codex-tmp/yisu-figma-phase2-state.json >/dev/null
git diff --check
```

预期：token 和 DESIGN 校验通过，JSON 合法，Git whitespace 错误为 0。

- [ ] **Step 4: 运行最终 Figma 审计**

一次性输出：组件集及变体数、页面数、P05/P09 来源差异、字体集合、描边违规、文本溢出、触控区违规、原型可达数和死链数。任何非零违规必须修复并重跑。

- [ ] **Step 5: 精确提交**

仅暂存本轮修改的跟踪文件和明确的新规格/计划；不使用 `git add .`，不纳入历史 `assets/` 或无关 evidence。提交信息：

```bash
git commit -m "design: deliver modular Gate B4 wardrobe flow"
```

- [ ] **Step 6: 交付用户验收**

报告 Figma 节点、关键页面、组件变体、原型审计、工作簿路径和提交哈希，并将 Gate B4 保持为 `awaiting_user_review`。
