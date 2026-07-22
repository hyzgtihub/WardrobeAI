# 衣序 YISU iOS 原生交付管理包调整设计

## 目标

将交付管理包从 Flutter 双端基线调整为 iOS 原生（SwiftUI/Xcode）基线，并以 2026-07-22 为新的计划起点。

## 调整范围

- 保持原有工作簿结构、样式、负责人、优先级、依赖追踪和 RAID 管理逻辑。
- 将原 2026-07-18 至 2026-07-31 的两周 Sprint 整体顺延 4 天，重排为 2026-07-22 至 2026-08-04。
- 将 Flutter、Android、双端、Drift 与 Flutter theme token 相关表述，替换为 SwiftUI、Xcode、iOS Simulator、XCTest、SwiftData/持久化队列和 SwiftUI 设计 token。
- Apple Developer 付费注册改为进入 TestFlight 或接入 Sign in with Apple 前的后置门禁；当前仅验证 Apple Account、Xcode 和 iOS Simulator。

## 受影响表

- 02 WBS：重写工程、设计系统、可靠性、认证、测试和发布验收；顺延计划日期。
- 04 RAID：重写工具链、离线可靠性和 Apple 账号依赖的检查项与缓解动作。
- 05 里程碑：改为 iOS 原生启动基线和 iOS 构建门禁；顺延日期。
- 07 Sprint Backlog：更新 Sprint 目标、任务、验收标准、依赖、下一动作和评审日期。
- 其余工作表仅替换直接出现的 Flutter/Android 技术表述，保留既有管理结构。

## 验收

- 全工作簿不再包含 Flutter、Android 或双端构建作为现阶段交付要求。
- Xcode 26.3、iOS Simulator、SwiftUI 工程、iOS build、XCTest 和 iOS 原生持久化成为对应验收标准。
- 新版工作簿保留原表结构与可读性，并以新文件交付，不覆盖原始工作簿。
