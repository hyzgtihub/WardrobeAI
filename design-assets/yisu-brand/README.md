# 衣序 YISU 品牌与导航资产

- `logo-mark.svg`：静态品牌图形，适用于启动页、登录页和 App 图标母版。
- `logo-lockup.svg`：图形、中文名、英文名与口号的横向组合。
- `navigation-icons.svg`：衣橱、添加衣物、我的三枚图标的选中/非选中状态。
- `motion-preview.html`：Logo 描边归序动效与可交互底栏状态动画。

## 动效参数

- Logo：1.15 秒描边 + 0.42 秒归位回弹，最终帧与静态 Logo 一致。
- 底栏：200–320ms，使用轻弹簧曲线；衣橱收拢、添加旋转、头像上浮。
- 已包含 `prefers-reduced-motion` 降级，减少动态效果时直接展示最终状态。

## 色彩

- Brand `#7666B5`
- Selected `#8E7BC7`
- Soft `#C8BDEB`
- Ink `#35313D`
- Background `#F7F3FC`
