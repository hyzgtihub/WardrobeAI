import Testing
@testable import YISU

struct FoundationTests {
    @Test("44×44 操作区满足最低触控要求")
    func minimumTouchTargetIsAccepted() {
        #expect(YISUTheme.Layout.isAccessibleTouchTarget(width: 44, height: 44))
    }

    @Test("任一边小于 44pt 的操作区不满足要求")
    func undersizedTouchTargetIsRejected() {
        #expect(!YISUTheme.Layout.isAccessibleTouchTarget(width: 43, height: 44))
        #expect(!YISUTheme.Layout.isAccessibleTouchTarget(width: 44, height: 43))
    }
}
