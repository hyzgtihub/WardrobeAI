# 衣序 YISU 设计基础与通用组件设计规格

## 目标

在现有 iOS 17、Swift 6、SwiftUI 工程内建立首批可独立开发和测试的设计系统能力，为 P05 衣橱首页与搜索页提供稳定基础，并为后续 P08、P09、P12 复用。

本批只实现设计基础与以下通用组件：Button、Content State、Category Chip/Filter、Garment Card/Grid、Bottom Navigation。登录改造、表单组件、导航编排、网络、数据库和 SwiftData 均不在本批范围内。

## 架构

设计系统保留在现有 `YISU` application target 内，不新增 Swift Package 或第三方依赖。代码按职责分为：

- `WardrobeApp/DesignSystem/Foundation`：颜色、字体、间距、圆角、阴影和触控尺寸。
- `WardrobeApp/DesignSystem/Models`：合法分类、衣物展示模型和组件状态。
- `WardrobeApp/DesignSystem/Components`：独立 SwiftUI 组件。
- `WardrobeAppTests/DesignSystem`：基础值、模型与状态行为测试。

页面持有状态，组件接收不可变配置，通过闭包报告用户事件。组件不得直接依赖数据库、网络、路由或具体页面。

## 设计基础

`YISUTheme` 提供 Gate B4 已确认的 Light Mode 语义值：背景、表面、品牌色、主次文字、边框、危险色，以及字体层级、4/8pt 间距体系、圆角、阴影和最小触控尺寸。

首批不实现 Dark Mode。颜色以语义名称暴露，组件不得直接散落 RGB 或十六进制常量。所有独立操作区最小为 `44×44pt`。

## 通用组件

### YISUButton

- 样式：Primary、Secondary。
- 状态：Default、Pressed、Disabled、Loading。
- Loading 与 Disabled 不发送点击事件；Loading 展示进度反馈。
- 最小高度 44pt，并提供稳定的无障碍标签和标识。

### YISUContentStateView

- 状态：Content、Empty、Loading、Error、No Results。
- 标题、说明和可选 CTA 从外部传入。
- CTA 行为通过闭包注入；Loading 不提供重复操作入口。

### YISUCategoryChip 与 YISUCategoryFilter

- 分类为固定枚举：全部、上衣、裤子、外套、裙子、鞋子、配饰、其他。
- 选择状态由父级传入，点击后只通过回调报告新选择。
- Filter 支持横向滚动，不压缩 44pt 触控高度。

### YISUGarmentCard 与 YISUGarmentGrid

- 使用轻量 `GarmentSummary` 展示模型，不依赖持久化实体。
- Card 状态：Default、Pressed、Loading、Image Error。
- 标题最多两行并尾部截断；元信息保持一行。
- 图片缺失或失败时显示固定尺寸占位，不改变卡片几何。
- Grid 只负责自适应两列布局和选择回调，不负责加载数据。

### YISUBottomNavigation

- 固定入口：衣橱、添加衣物、我的。
- 当前选中项由父级传入，点击通过回调报告目标。
- 不直接执行 NavigationStack 跳转。

## 数据流与降级

组件遵循单向数据流。合法状态由明确枚举表示，避免任意字符串。图片错误、加载和禁用状态必须保持布局稳定。Disabled 与 Loading 操作不得触发业务闭包。

本批不创建全局状态管理器，不提前设计服务层，也不修改现有 Apple 登录占位页；这些工作由后续独立批次处理。

## 测试与验收

- 单元测试覆盖 Token 关键值、八个分类、衣物展示模型与组件状态映射。
- 可交互组件将事件启用规则提取为可测试状态逻辑；不引入 ViewInspector。
- UI 冒烟测试通过仅在 UI Test 启动参数下显示的组件展示入口，验证关键组件存在、分类与底栏事件可达，以及 Disabled/Loading 不产生操作结果。
- SwiftUI Preview 仅用于开发检查，不替代自动化测试。
- 最终验收必须包含完整 build、单元测试和 UI 测试；独立触控区小于 44pt 为 0。

## 非目标

- 不实现完整 P05 或搜索页面。
- 不实现 P08 表单组件、P09 编辑、P12 资料模块。
- 不接入后端、认证、图片上传、缓存或持久化。
- 不引入第三方 UI、图片或测试库。
