import Testing
@testable import YISU

struct ControlBehaviorTests {
    @Test(arguments: [YISUControlState.disabled, .loading])
    func buttonPolicyBlocksInactiveStates(_ state: YISUControlState) {
        #expect(!YISUButtonPolicy.canSendAction(in: state))
    }

    @Test(arguments: [YISUControlState.normal, .pressed])
    func buttonPolicyAllowsActiveStates(_ state: YISUControlState) {
        #expect(YISUButtonPolicy.canSendAction(in: state))
    }

    @Test("加载内容状态不提供操作")
    func loadingContentHasNoAction() {
        #expect(!YISUContentState.loading.allowsAction)
    }

    @Test("可恢复内容状态允许操作", arguments: [
        YISUContentState.empty,
        .error,
        .noResults
    ])
    func recoverableContentStatesAllowActions(_ state: YISUContentState) {
        #expect(state.allowsAction)
    }

    @Test("分类选择返回用户点击项")
    func categorySelectionReturnsTappedCategory() {
        #expect(YISUCategorySelection.select(.tops, current: .all) == .tops)
    }
}
