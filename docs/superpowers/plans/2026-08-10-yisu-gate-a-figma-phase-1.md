# YISU Gate A Figma Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在既有 Figma 文件中建立衣序 YISU Gate A 的用户流程、P01–P12 全部低保真页面、必要基础组件和可点击核心旅程。

**Architecture:** Figma 云端文件是设计源，本地需求文档是范围源，本地 state ledger 记录所有创建对象 ID。按“发现 → Token → 页面结构 → 组件 → 页面 → 原型连线 → QA”顺序小批量写入，每个批次后检查结构和截图。

**Tech Stack:** Figma Design、Figma Plugin API、Codex Figma connector、SwiftUI/iOS HIG 语义、Markdown 需求文档。

## Global Constraints

- Figma file key：`UMn1NvC2IUOA4xlXpLETRL`。
- 设计依据：`衣序YISU-GateA-AI原型设计需求-20260810.md`。
- 仅覆盖 Gate A；认证方式仅为邮箱 + 密码。
- 第一阶段交付为流程图、P01–P12 低保真、可点击主流程；不提前制作最终高保真视觉。
- 使用 iPhone 原生 NavigationStack、Sheet、Alert、搜索和 PhotosPicker 语义。
- 不加入 Apple/微信/手机号登录、AI、搭配、OOTD、支付、社区和底部四栏导航；主导航固定为“衣橱｜添加衣物｜我的”。
- 所有 Figma 写入必须返回节点 ID，并同步到本地 state ledger。

---

### Task 1: Discovery and scope lock

**Files:**
- Read: `衣序YISU-GateA-AI原型设计需求-20260810.md`
- Read: `WardrobeApp/Features/Auth/SignInView.swift`
- Read: `WardrobeApp/App/RootView.swift`
- Create: `.codex-tmp/yisu-figma-phase1-state.json`

**Interfaces:**
- Consumes: confirmed Gate A requirements and Figma file key.
- Produces: page, token, component, font, and library inventory.

- [ ] **Step 1:** Inspect code tokens, assets, view hierarchy, and naming.
- [ ] **Step 2:** Inspect Figma pages, variables, styles, components, and fonts without writes.
- [ ] **Step 3:** Discover Apple/iOS and team libraries before rebuilding controls.
- [ ] **Step 4:** Record the locked page/component/token list and conflicts in the state ledger.
- [ ] **Step 5:** Present the gap analysis and obtain the required Phase 0 approval.

### Task 2: Low-fidelity foundations

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase1-state.json`

**Interfaces:**
- Consumes: locked token and style map from Task 1.
- Produces: local Figma variables and text styles used by all components and screens.

- [ ] **Step 1:** Create primitive, semantic color, spacing, and radius collections with explicit scopes and iOS code syntax.
- [ ] **Step 2:** Create only the typography and effect styles needed by low-fidelity pages.
- [ ] **Step 3:** Inspect variable counts, scopes, modes, and style names.
- [ ] **Step 4:** Save created collection, variable, and style IDs to the state ledger.

### Task 3: File and flow structure

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase1-state.json`

**Interfaces:**
- Consumes: foundations from Task 2.
- Produces: Cover, Flow, Foundations, Components, and Wireframes pages.

- [ ] **Step 1:** Create the named page skeleton without duplicates.
- [ ] **Step 2:** Create cover and scope notes.
- [ ] **Step 3:** Create the Gate A user-flow artifact and page index.
- [ ] **Step 4:** Create low-fidelity token documentation.
- [ ] **Step 5:** Validate page names, order, and screenshots.

### Task 4: Low-fidelity component kit

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase1-state.json`

**Interfaces:**
- Consumes: variables, text styles, and reusable iOS library assets.
- Produces: Button, Text Field, Chip, Garment Card, Navigation, Sheet, Alert, Empty/Error/Loading components.

- [ ] **Step 1:** Build and validate Button states.
- [ ] **Step 2:** Build and validate Text Field and Secure Field states.
- [ ] **Step 3:** Build and validate Chip and Garment Card.
- [ ] **Step 4:** Build and validate feedback and overlay components.
- [ ] **Step 5:** Audit component bindings, naming, and 44 pt minimum targets.

### Task 5: P01–P12 wireframes

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase1-state.json`

**Interfaces:**
- Consumes: component instances from Task 4.
- Produces: all required low-fidelity screen frames and state variants.

- [ ] **Step 1:** Build and validate P01–P03 account and initialization screens.
- [ ] **Step 2:** Build and validate P04–P06 role, wardrobe, search and filter screens.
- [ ] **Step 3:** Build and validate P07–P08 photo preview and garment creation screens.
- [ ] **Step 4:** Build and validate P09–P12 detail, edit, delete, and global feedback states.
- [ ] **Step 5:** Compare the screen/state inventory against the requirements table.

### Task 6: Prototype wiring and QA

**Files:**
- Modify: `.codex-tmp/yisu-figma-phase1-state.json`
- Modify: `figma-deliverables/衣序YISU-GateA原型与UI设计/README.md`

**Interfaces:**
- Consumes: P01–P12 screen node IDs.
- Produces: clickable Gate A prototype, QA record, and local handoff link.

- [ ] **Step 1:** Wire registration, empty wardrobe, add garment, search, edit, and delete journeys.
- [ ] **Step 2:** Audit scope violations, dead links, naming, accessibility notes, and minimum target sizes.
- [ ] **Step 3:** Capture final screenshots and inspect for clipping, overlap, and broken states.
- [ ] **Step 4:** Record Figma node links, completion status, and remaining high-fidelity work in the local README.
