# 衣序 YISU 品牌与导航规范 V2

## 设计概念

“Quiet Luxury Wardrobe”以衣架、衣领、秩序层叠为核心母题。品牌的女性感来自柔和曲率、克制比例和低饱和葡萄紫，而非粉色或装饰性符号。

## Logo 几何

- 基础画布：256 × 256pt。
- 安全区：四周至少 32pt；安全区内不得放置文字或其他高对比元素。
- 标准描边：8pt，圆形端点及连接。
- 最小数字尺寸：24pt；24–31pt 时隐藏浅紫色底层弧线，只保留主轮廓与衣领线。
- 图形与中文名称间距：20pt。
- 中文：PingFang SC Semibold；英文：Avenir Next Medium，字距 0.18em。
- 禁止拉伸、旋转、描边变粗、渐变、投影、外发光及擅自替换颜色。

## 色彩 Token

| Token | 色值 | 用途 |
|---|---:|---|
| Brand 700 | `#594D85` | Logo 主线、选中图标、品牌按钮 |
| Brand 600 | `#6F619D` | 辅助品牌强调 |
| Brand 500 | `#8B7DB4` | Logo 衣领线、次级强调 |
| Brand 200 | `#D8D0EA` | 选中态局部填充、焦点环 |
| Brand 100 | `#EEEAF6` | 柔光背景、选中容器 |
| Canvas | `#FAF8FB` | App 基础背景 |
| Surface | `#FFFFFF` | 卡片及底栏表面 |
| Ink | `#292630` | 主文字 |
| Text Secondary | `#716B78` | 次级文字 |
| Icon Inactive | `#96909D` | 未选中导航图标 |

## 底部导航

- 图标画布：24 × 24pt，光学内边距 2pt。
- 描边：默认 1.75pt；选中 2pt。
- iOS 触控区域：至少 44 × 44pt。
- 图标和标签间距：4pt；标签 11pt Medium。
- 选中容器：32 × 32pt，Brand 100；不得改变布局边界。
- 底栏最多五项；衣序固定为三项：衣橱、添加衣物、我的。
- 选中态同时使用颜色与局部形态/填充，避免仅依赖颜色传达状态。

## 动效 Token

| Token | 数值 | 用途 |
|---|---:|---|
| Instant | 120ms | 按压反馈 |
| Fast | 240ms | 导航状态切换 |
| Brand | 960ms | Logo 完整演绎 |
| Standard easing | `cubic-bezier(.22,1,.36,1)` | 线条绘制及归位 |
| Emphasized easing | `cubic-bezier(.34,1.32,.64,1)` | 小范围状态强调 |

Logo 动画只播放一次，不自动循环。导航图标最多同时动画两个视觉属性，位移不超过 2pt，缩放不超过 0.96–1.04。开启 Reduce Motion 时直接呈现最终状态。

## 文件

- `logo-mark.svg`：独立品牌图形。
- `logo-lockup-horizontal.svg`：横向组合标。
- `navigation-icons.svg`：24pt 网格及状态板。
- `tokens.css`：可复用视觉与动效 Token。
- `motion-preview.html`：品牌与底栏交互预览。
