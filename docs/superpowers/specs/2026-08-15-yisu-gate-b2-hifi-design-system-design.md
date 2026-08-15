# 衣序 YISU｜Gate B2 高保真设计系统隔离与交付规格

日期：2026-08-15

状态：方案已确认，待用户复核书面规格

设计文件：`衣序 YISU｜Gate A 原型与 UI 设计｜2026-08-10`
前置门禁：Gate B1 已于 2026-08-15 通过

## 1. 目标

建立一套与低保真资产完全隔离、可供后续高保真页面直接复用的衣序设计系统。系统同时服务 Figma 设计、AI 生成页面、人工验收和 SwiftUI 开发，避免颜色、字号、间距、圆角、阴影及组件状态在后续页面中被重复定义或自由发挥。

Gate B2 的正式交付物为：

1. Figma 高保真 Foundations。
2. Figma 高保真组件库。
3. `DESIGN.md` 人类与 AI 可读设计契约。
4. `tokens.json` 机器可读设计 Token。
5. Figma Token、JSON Token 与 SwiftUI 命名对照。
6. Gate B2 验收板、审计结果和状态台账。

## 2. 隔离原则

### 2.1 低保真资产

- 现有 `02 Foundations`、`03 Components` 视为 Gate A 低保真历史基线。
- 不修改其变量值、文字样式、组件结构或页面内容。
- 不删除、不覆盖、不将其组件作为高保真页面的正式依赖。
- 低保真资产仅用于回溯信息结构、流程和已确认交互含义。

### 2.2 高保真资产

- 新建独立页面 `06A Hi-Fi Foundations` 与 `06B Hi-Fi Components`。
- 高保真变量、样式和组件均使用 `YISU Hi-Fi` 命名空间。
- `07 Hi-Fi Screens` 及后续高保真页面只能使用高保真变量、样式和组件实例。
- 允许参考 Apple iOS 26 官方设计库的系统结构和尺寸，但不把 Material 3 或其他平台组件引入衣序的正式组件体系。
- Apple 系统组件只有在视觉、属性和 SwiftUI 语义均匹配时才复用；衣序品牌组件保持本地可编辑与可维护。

## 3. Figma 信息架构

### 3.1 页面

- `06 Hi-Fi Exploration`：保留 B1 视觉探索和验收历史。
- `06A Hi-Fi Foundations`：颜色、字体、间距、圆角、阴影、栅格、安全区域、图标和图片规则。
- `06B Hi-Fi Components`：高保真组件、变体、状态、用法与禁用示例。
- `07 Hi-Fi Screens`：使用设计系统组件组成的正式高保真页面。
- `08 Hi-Fi Prototype`：高保真可点击流程。
- `09 Dev Handoff`：Token 对照、组件索引、尺寸标注和开发注意事项。

### 3.2 变量集合

高保真系统使用独立集合，不复用现有低保真集合：

- `YISU Hi-Fi / Primitives`：原始颜色和值，单一 `Value` 模式。
- `YISU Hi-Fi / Semantic Colors`：界面语义色，第一阶段只有 `Light` 模式。
- `YISU Hi-Fi / Layout`：间距、圆角、尺寸和布局常量，单一 `Value` 模式。

本阶段不创建 Dark Mode。所有变量必须设置明确 Scope 和 iOS Code Syntax；原始变量隐藏或限制为无 Scope，页面与组件只能绑定语义变量。

## 4. Foundations 范围

### 4.1 颜色

以 Gate B1 已确认的 V3B「柔焦衣间」为唯一视觉来源。核心方向包括：

- 奶油白与暖白页面背景。
- 柔焦灰蓝、薰衣草紫、复古肉粉、鼠尾草绿和极淡米卡其。
- 深灰紫黑正文色，避免纯黑造成工具感。
- 成功、警告、错误等功能色只表达状态，不承担装饰。

颜色至少覆盖：页面背景、表面、分层卡片、四种衣物卡片柔焦底色、主操作、按下、禁用、主要文字、次要文字、反色文字、默认描边、聚焦描边、分隔线、图标、成功、警告、错误及遮罩。

### 4.2 字体与字号

- 正式高保真字体使用 `SF Pro Rounded`。
- 建立 Display、Large Title、Title 1、Title 2、Headline、Body、Callout、Subheadline、Footnote 和 Caption 层级。
- 每个文字样式必须记录字号、字重、行高、字间距、用途及 SwiftUI 映射。
- 系统数据、长文本或平台组件在需要时可使用 `SF Pro`，但不得与品牌标题样式混用。
- Dynamic Type 的实际适配由 SwiftUI 实现；Figma 记录基准字号和放大后的布局约束。

### 4.3 间距与栅格

- 采用 8pt 主栅格，允许 4pt 微调。
- 建议基础序列为 `4、8、12、16、20、24、32、40、48、64`。
- 页面水平安全边距、卡片内边距、字段间距、区块间距和底部导航安全区必须分别定义语义 Token。
- 高保真组件不得通过任意像素值修补对齐。

### 4.4 圆角

建立 `8、12、16、20、24、32、full` 七档圆角，并通过语义说明限定其用途：小控件、输入框、普通卡片、主卡片、设备容器和胶囊标签。

### 4.5 阴影

建立至少三档效果样式：

- `Subtle`：分隔页面表面与背景。
- `Card`：衣物卡片和内容卡片。
- `Floating`：中央添加按钮、浮层和需要强调的操作。

阴影使用柔和紫灰或中性灰，避免纯黑重阴影。每档记录偏移、模糊、扩散、透明度和适用场景。

### 4.6 图标

- 默认采用 SF Symbols，并按符号名称记录，不使用手工 Unicode 码点。
- 统一 16、20、24pt 视觉尺寸和不小于 44×44pt 的独立触控区域。
- 记录图标名称、语义、线宽、选中/未选中表现和 SwiftUI `Image(systemName:)` 名称。
- Logo 主题 Icon 与动效仍为后续专项，不阻塞 Gate B2。

### 4.7 衣物图片

- 使用真实衣物抠图，放置于暖白或极淡柔焦彩色背景。
- 统一主体占比、留白、裁切、对齐、圆角、背景色用途和异常占位规则。
- 禁止在同一列表中混用不同光线、不同透视和不一致主体尺度。

## 5. 高保真组件库范围

组件以 `YISU Hi-Fi/<Component>` 命名，并使用 Auto Layout、变量绑定和组件属性。首批组件包括：

- Button。
- Form Field。
- Category Chip。
- Garment Card。
- Navigation Bar。
- Bottom Tab Bar。
- Checkbox。
- Selection Row。
- Tag。
- Empty State。
- Error State。
- Loading Skeleton。
- Toast。
- Alert。
- Action Sheet。
- Photo Upload。

每个组件只建立真实需要的状态。根据组件语义覆盖 Default、Pressed、Selected、Focused、Filled、Disabled、Loading、Error 或 Destructive，避免无业务用途的变体组合。所有主要操作和独立图标按钮的触控区域不得小于 44×44pt。

## 6. `DESIGN.md`

`DESIGN.md` 是 Figma 与实现之间的书面设计契约，不替代 Figma，也不替代机器 Token。文件存放于：

`figma-deliverables/衣序YISU-GateA原型与UI设计/DESIGN.md`

其内容包括：

- 设计原则、适用范围和范围外事项。
- 高保真与低保真隔离规则。
- 颜色、字体、间距、圆角和阴影规范。
- 图标、图片和无障碍规范。
- 组件清单、属性、状态和使用限制。
- Figma 变量与 SwiftUI 命名对照。
- Figma 页面和关键节点索引。
- 版本号、修改记录、废弃与迁移规则。

AI 工具生成后续页面时，必须先读取 `DESIGN.md` 和 `tokens.json`，再使用 Figma 高保真组件。不得只根据单张截图猜测设计语言。

## 7. `tokens.json`

机器 Token 文件存放于：

`figma-deliverables/衣序YISU-GateA原型与UI设计/tokens.json`

采用接近 Design Tokens Community Group 的分层结构，至少包含：

- `color.primitive`。
- `color.semantic`。
- `spacing`。
- `radius`。
- `size`。
- `typography`。
- `shadow`。
- `motion` 仅保留未来可用的基础时长与缓动规范；本阶段不制作品牌动效。

每个 Token 包含 `$type`、`$value`、`description` 和 `extensions.swiftUI`。语义 Token 通过引用指向原始 Token，不复制原始值。文件必须通过 JSON 语法校验，并与 Figma 变量、文字样式和效果样式逐项核对。

## 8. SwiftUI 对照

本阶段不直接重构现有 SwiftUI 页面，但要定义稳定命名：

- 颜色：`Color.yisuBackgroundPrimary` 等。
- 间距：`YISUSpacing.sm` 等。
- 圆角：`YISURadius.card` 等。
- 字体：`YISUTypography.title1` 等。
- 阴影：`YISUShadow.card` 等。
- 图标：保留 SF Symbols 的正式名称。

当前 `SignInView.swift` 仍是旧 Apple 登录工程骨架，不能反向覆盖已经确认的邮箱密码产品范围和 V3B 视觉系统。真正实现页面时再依据 `DESIGN.md`、`tokens.json` 和高保真组件更新代码。

## 9. 同步与变更流程

### 9.1 数据流

1. 用户确认 V3B 视觉方向。
2. Figma Foundations 固化视觉值与语义。
3. 同步生成 `tokens.json`。
4. `DESIGN.md` 解释 Token 和组件的使用规则。
5. 高保真组件绑定 Figma 变量。
6. 后续页面只使用高保真组件实例。
7. SwiftUI 实现依据 Token 对照落地。

### 9.2 变更规则

- Foundations 发生变更时，Figma、`tokens.json`、`DESIGN.md` 和项目交付管理包必须在同一批次同步。
- 颜色或尺寸只允许在 Token 层修改，不允许逐页修补。
- 组件 API 变更必须记录影响页面和迁移方式。
- 已废弃 Token 保留一轮迁移期，并在 `DESIGN.md` 标记替代项。

## 10. 验收与测试

### 10.1 Foundations

- 高保真和低保真变量集合、样式与组件没有交叉依赖。
- 所有高保真变量具备 Scope、iOS Code Syntax 和说明。
- `tokens.json` 与 Figma 值一致，引用可解析且 JSON 校验通过。
- `DESIGN.md` 无待定项、占位符或未解释缩写。

### 10.2 组件

- 所有组件使用 Auto Layout 和高保真变量绑定。
- 状态命名一致，不存在无意义或缺失的必要状态。
- 主要触控区域不小于 44×44pt。
- 长中文、动态昵称、错误文案和加载状态不会造成异常截断。
- 组件实例可在 P01、P05、P09 中替换验证，不改变已确认的信息结构。

### 10.3 跨资产一致性

- Figma、`DESIGN.md`、`tokens.json` 和 SwiftUI 对照中的名称和值一致。
- 高保真页面中无低保真组件实例或旧变量绑定。
- Gate B2 验收板清楚列出通过项、后续专项和范围外内容。

## 11. Gate B2 完成条件

只有同时满足以下条件，Gate B2 才可提交用户确认：

1. 高保真 Foundations 页面完成并通过审计。
2. 首批组件及其状态完成并通过审计。
3. `DESIGN.md` 与 `tokens.json` 完成且相互一致。
4. SwiftUI Token 对照完整。
5. P01、P05、P09 使用新设计系统进行替换验证。
6. 用户明确确认 Gate B2。

Gate B2 未通过前，不开始 Gate B3 批量高保真页面制作。
