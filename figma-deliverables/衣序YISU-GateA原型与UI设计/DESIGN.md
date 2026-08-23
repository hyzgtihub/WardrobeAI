# 衣序 YISU 高保真设计系统

> 版本：Gate B2 / 1.1.0（Gate B1 无描边确认稿重新校准）
> 视觉方向：V3B · 柔焦衣间
> 适用范围：iOS MVP 高保真 UI、Figma 组件、SwiftUI 实现与 AI 辅助生成
> 机器可读规范：[tokens.json](./tokens.json)

## 1. 文档作用与单一真源

`DESIGN.md` 是衣序高保真视觉与交互实现的书面契约。它回答“为什么这样设计、何时使用哪个 token 或组件、页面完成后如何验收”；`tokens.json` 保存可以被脚本、Figma 和 SwiftUI 消费的精确数值。两者缺一不可。

本轮唯一视觉源是 Figma `06 Hi-Fi Exploration` 中 `Gate B1 · V3B 视觉一致性验收 · CONFIRMED`（节点 `293:2`）的无描边 P01/P05/P09（节点 `294:5`、`294:48`、`294:100`）。Figma 紫色选中框不是界面描边，任何页面级容器的外描边必须为 `0`。

规范优先级为：已确认产品需求与交互规则 → 上述 Gate B1 三张确认稿 → 本文档与 `tokens.json` → `06A/06B` 高保真系统 → 后续页面实例 → SwiftUI。旧 SwiftUI 登录骨架、历史探索稿或低保真值不得反向覆盖本基线。发现冲突时不得静默折中，应回到三张确认稿重新提取并同步下游资产。

## 2. 高低保真隔离

- 低保真基线：Figma `02 Foundations`、`03 Components`、`04 Wireframes`、`05 Prototype`。用于确认范围、信息结构、状态和流程，不承载最终视觉值。
- 高保真系统：Figma `06A Hi-Fi Foundations`、`06B Hi-Fi Components`，以及 `07 Hi-Fi Screens`、`08 Hi-Fi Prototype`、`09 Dev Handoff`。
- 高保真变量、样式和组件统一使用 `YISU Hi-Fi/` 命名空间；禁止覆盖或重命名原低保真集合与组件。
- 页面不得从低保真颜色、文字样式或组件继承最终视觉；历史稿只作追溯。

## 3. 品牌原则

衣序通过“温暖的秩序感”帮助用户整理私人衣物。设计必须同时满足：

1. 有序：严格使用 8 pt 主栅格和 4 pt 微调，建立清晰对齐关系。
2. 温和：以 `#F8F5FC` / `#F8F6FB` 画布、`#FFFCFE` 表面和柔焦彩色代替冰冷纯白与沉闷冷灰。
3. 时尚：衣物本身是视觉主角，使用真实衣物抠图、克制装饰和稳定的排版层级。
4. 轻松：使用大圆角、足够留白和轻阴影，避免工具软件般密集和生硬。
5. 清楚：所有交互入口、状态、错误和自动保存结果都必须可识别，不以装饰牺牲可用性。

## 4. 颜色

所有精确色值及语义映射见 `tokens.json` 的 `color`。页面只引用 `color.semantic.*`；`color.primitive.*` 仅用于建立语义映射和设计系统展示。

- `background`：P01/P09 的 `#F8F5FC` 画布；`backgroundWarm`：P05 的 `#F8F6FB` 画布。
- `surface`：`#FFFCFE` 卡片、输入框、浮层和导航。
- `brand / brandEmphasis / brandSubtle`：`#8D7AB5`、`#7D6AA5`、`#C9C0E8`。
- `accentBlue / accentBlush / accentKhaki / accentLavender / accentSage`：衣物图片区和辅助标签的低饱和背景；不表示业务状态。
- `textPrimary / textSecondary / textPlaceholder`：三级文本层级。
- `success / danger`：仅用于真实状态，不用于装饰。
- `border / borderIcon`：只用于确认稿中真实存在的输入框、换图按钮与 44pt 图标按钮；`divider` 专用于信息行。

对比要求：正文和关键控件需达到 WCAG AA；浅彩背景上优先使用 `textPrimary`，不得用浅彩文本承载关键内容。

## 5. 排版

高保真统一使用 `SF Pro Rounded`，中文由 iOS 字体回退机制保证可读性。不得在页面内混用 Inter、苹方的硬编码样式或未知网络字体。完整值见 `typography` token。

- Home Title：34/41 Bold，例如“我的衣橱”。
- Brand Title：31/37 Bold，例如“衣序 YISU”。
- Item Title：28/34 Bold；Welcome：22/28 Semibold；Page Title：20/24 Semibold。
- Button：16/20 Semibold；Body：15/20 Regular；Value：14/19 Medium。
- Label：13/18 Semibold；Footnote：13/18 Regular；Metadata/Status：11/15；Navigation Label：10/13 Semibold。

字号层级必须来自 token。不得为了“塞下内容”临时缩小字体；优先调整布局、换行或滚动策略。正文动态字体放大后不得遮挡操作入口。

## 6. 栅格与间距

- 8 pt 为主栅格，4 pt 仅用于图标光学校准和紧凑文本关系。
- 页面默认水平边距为 20 pt；内容卡片内部通常为 20–24 pt。
- 相关元素间距为 8–16 pt；区块间距为 24–32 pt；页面章节可使用 40–64 pt。
- 所有值必须来自 `spacing` token；新增数值需先进入 token 再用于页面。
- 安全区域由 iOS 容器控制，不用额外绘制黑色 Home Indicator；Figma 演示需要时必须几何居中。

## 7. 圆角、描边与阴影

- 圆角直接来自确认稿：复选框 8；状态胶囊 15；输入框 18；标签 19；主按钮 20；分类选中项 21；44pt 控件 22；衣物图 24；搜索 26；内容卡 30；Hero 32；底部导航 34；Figma 屏幕容器 36。
- 页面级容器禁止外描边；卡片、衣物卡、Hero、底部导航也不增加装饰性描边。仅输入框、换图按钮和图标按钮保留 1 pt 语义边界。
- 焦点态使用品牌色替换控件边界，不叠加多层轮廓；选中状态依靠底色、文字和图标表达。
- 阴影采用上下文 token：`subtle`、`card`、`loginCard`、`hero`、`floatingNavigation`、`primaryAction`、`changePhoto`。列表行只使用 `divider`，不添加阴影。

## 8. 图标

- 正式实现优先使用 Apple SF Symbols；同一页面保持统一的线性风格、圆角端点和视觉重量。
- 常规图标建议 20–24 pt，最小触控区域 44×44 pt；图形可以光学校准，但触控框必须对齐栅格。
- 图标必须表达明确意图：返回、搜索、换图、显示/隐藏密码、更多、删除等不得使用语义含糊的替代符号。
- 底部导航为“衣橱｜添加衣物｜我的”；中间为 60×60 pt 圆形主操作，使用清晰加号。
- 品牌圆标与整套导航图标的精细造型、动效属于后续专项；在专项完成前采用同一 SF Symbols 基线，不制作伪品牌图标。

## 9. 衣物图片

- 主风格：真实衣物抠图 + 暖白或极淡彩色背景。
- 同一列表中的图片保持正面商品视角、近似占比、统一光感；不出现人物、品牌水印、文字、强烈阴影或复杂场景。
- 图片必须使用 `aspectFit`，不得拉伸或裁掉衣物关键结构。背景可在 `accentBlue`、`accentBlush`、`accentSage`、`surfaceSubtle` 间按内容平衡选择。
- 加载、空白、失败和换图失败必须使用组件状态表达；不得以永久色块占位冒充最终图片。

## 10. 核心组件

以下 16 个组件构成 Gate B2 最小高保真组件库。Figma 组件名统一以 `YISU Hi-Fi/` 开头。

### 10.1 YISU Hi-Fi/Button

用途：主要、次要与破坏性操作。状态：Default、Pressed、Disabled、Loading。公开文本属性为 `CTA Label#582:0`，8 个变体均可覆盖；默认文案按变体保持 Primary=`完成`、Secondary=`取消`、Loading=`处理中…`。P01 确认稿尺寸为 `302×56`、圆角 `20`；最小触控区 44 pt。一个页面通常只保留一个主要按钮。

### 10.2 YISU Hi-Fi/Icon Button

用途：返回、搜索、更多、密码可见性等单图标操作。状态：Default、Pressed、Disabled；确认稿尺寸 `44×44`、圆角 `22`。必须配置无障碍标签。

### 10.3 YISU Hi-Fi/Text Field

用途：邮箱、密码、名称、品牌、价格等输入。状态：Empty、Filled、Focused、Error、Disabled；可选前后图标和帮助文本。P01 确认稿尺寸为 `302×58`、圆角 `18`，错误态需同时给出文字原因。

### 10.4 YISU Hi-Fi/Checkbox

用途：登录、注册协议确认。状态：Checked、Unchecked、Disabled；视觉控件配套 44×44 pt 触控区域。取消勾选后登录按钮禁用，界面不重复展示冗余解释。

### 10.5 YISU Hi-Fi/Category Chip

用途：衣橱分类筛选及多选标签。状态：Default、Selected、Disabled；支持内容自适应宽度。选中态必须同时通过底色和文本对比表达。

### 10.6 YISU Hi-Fi/Tag

用途：详情页显示分类、季节等非主操作信息。状态：Blue、Blush、Sage、Lavender、Neutral；不可与筛选 Chip 混淆。

### 10.7 YISU Hi-Fi/Garment Card

用途：衣橱两列网格。状态：Default、Pressed、Loading、Image Error；确认稿卡片 `168×226`、圆角 `30`，图片 `144×154`、圆角 `24`；包含真实衣物图、名称和次级元数据。卡片点击进入 P09 直接编辑详情。

### 10.8 YISU Hi-Fi/Editable Field Row

用途：P09 进入即编辑的字段行。状态：Idle、Pressed、Saving、Saved、Error、Offline；确认稿尺寸 `326×48`，使用 `divider` 分隔而非行描边；支持单选、多选、文本、日期与层级选择入口。选择类字段变更后立即保存，文本字段停止输入后约 800 ms 提交。

### 10.9 YISU Hi-Fi/Photo Hero

用途：P08/P09 顶部衣物主图。状态：Loaded、Loading、Error；P09 确认稿 Hero `350×300`、圆角 `32`，右下角始终提供 `84×44`、圆角 `22` 的“换图”入口。取消选图返回原始入口页面。

### 10.10 YISU Hi-Fi/Auto-save Status

用途：反馈自动保存。状态：Saving、Saved、Error、Offline；错误态提供明确重试入口。短暂成功提示不得阻塞继续编辑。

### 10.11 YISU Hi-Fi/Bottom Navigation

用途：MVP 全局导航。状态：Wardrobe Selected、Profile Selected；确认稿导航 `326×67`、圆角 `34`，中间 `60×60` 添加衣物主操作不是 Tab。选中状态通过图标、文字和柔和彩底共同表达。

### 10.12 YISU Hi-Fi/Navigation Bar

用途：页面标题与返回/更多操作。状态：Root、Back、More、Back + More；左右操作触控区均不低于 44×44 pt，图标与背景共用几何中心。

### 10.13 YISU Hi-Fi/Empty State

用途：空衣橱、无搜索结果。包含语义图标或插图、标题、说明和可选主操作。空衣橱主操作进入新增衣物。

### 10.14 YISU Hi-Fi/Error State

用途：页面加载失败、保存失败和图片失败。包含标题、可行动说明及重试；不得只显示红色或错误码。

### 10.15 YISU Hi-Fi/Loading Skeleton

用途：列表、卡片和详情加载。使用低对比暖灰/浅紫，不模拟真实文本；减少动态效果开启时停用闪动。

### 10.16 YISU Hi-Fi/Sheet / Dialog

用途：删除确认、选项选择、离线退出确认和错误提示。状态：Standard、Destructive；明确主次操作，遮罩使用 `overlay`，破坏性操作不得默认获得安全色。

## 11. 交互与状态

- 所有可交互控件必须覆盖 Default、Pressed、Disabled；涉及异步操作时增加 Loading、Success、Error，涉及离线时增加 Offline。
- P09 是详情即编辑页：不显示“编辑”或“保存”按钮。字段修改后自动保存；更多菜单仅保留删除及相关操作。
- P08 是创建流程：主操作为“完成添加”；P08 与 P09 均在主图右下角提供“换图”。
- 协议链接“服务条款”“隐私政策”使用品牌强调色并进入独立纯文本页。
- 动效使用 `motion` token，服务于状态理解；减少动态效果开启时提供无位移或淡入替代。

## 12. 无障碍与质量门槛

- 所有操作触控区域至少 44×44 pt；主要输入与按钮遵循 `size` token。
- 颜色不是唯一状态信号；需配合文本、图标或形态变化。
- VoiceOver 标签描述动作结果，而非只读图标名，例如“显示密码”“更换衣物照片”。
- 支持 Dynamic Type；超长昵称、衣物名和字段值需要有换行或截断策略。
- 页面验收必须检查：安全区域、栅格、触控尺寸、文字溢出、状态完整、图标一致、图片质量、组件复用、交互意图、交付证据。

## 13. Figma → tokens.json → SwiftUI 映射

| 层 | 命名 | 用途 |
|---|---|---|
| Figma Variables | `YISU Hi-Fi / Primitives`、`Semantic Colors`、`Layout` | 设计编辑与组件绑定 |
| Figma Styles | `YISU Hi-Fi/Typography/*`、`YISU Hi-Fi/Shadow/*` | 排版和阴影复用 |
| JSON | `color.semantic.brand` 等 | 机器读取、验证和跨平台转换 |
| SwiftUI | `Color.yisuBrand`、`YISUSpacing.md` 等 | iOS 代码调用 |

SwiftUI 名称以每个 token 的 `extensions.swiftUI` 为准。实现时禁止在业务 View 中散落十六进制颜色、私有字号或未登记间距；设计验收发现偏差时先定位到 token 或组件层。

## 14. AI 生成页面的前置条件

AI 工具生成或修改高保真页面前，必须同时读取：PRD、当前页面交互说明、本 `DESIGN.md` 和 `tokens.json`。生成结果必须：

1. 只使用 `YISU Hi-Fi` 变量、样式和组件；
2. 不改动低保真页面和历史节点；
3. 覆盖正常、加载、空白、错误、无结果、校验、禁用、保存中和删除失败等适用状态；
4. 输出页面与组件实例清单，并执行第 12 节质量检查；
5. 不擅自扩展 MVP 范围，例如搭配、AI、宝宝角色或其他登录方式。

## 15. 版本、变更与废弃

- token 或组件发生破坏性变化时提升主版本；新增兼容项提升次版本；数值修正提升补丁版本。
- 变更顺序：确认视觉源 → 更新 `06A/06B` → 同步 `tokens.json` 与本文档 → 自动校验 → 页面回归 → 更新 SwiftUI。不得再次从旧代码或历史探索稿反推颜色与几何。
- 被替换组件至少保留一个交付周期并添加 `Deprecated` 标识；历史稿不得删除。
- Gate B2 通过后，本系统成为后续高保真页面的默认基线；任何项目周期相关调整继续同步项目交付管理包。

## 16. Gate B2 验收标准

- `tokens.json` 结构、引用、SwiftUI 映射校验通过。
- 本文档章节完整、无未决占位语句，16 个核心组件均有用途和状态定义。
- Figma 高低保真完全隔离；高保真变量、样式、组件均使用命名空间。
- `06A Hi-Fi Foundations` 展示颜色、排版、间距、圆角、阴影、图标与图片规范。
- `06B Hi-Fi Components` 覆盖 16 个组件及必要状态，并通过实例复用检查。
- P01、P05、P09 三个确认稿及其后续页面副本的屏幕级 `stroke = 0`；不得把编辑选中框固化为视觉描边。
- P01、P05、P09 使用同一高保真系统回归，无硬编码视觉偏差、触控尺寸不足和非预期溢出。
