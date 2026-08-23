import Testing
@testable import YISU

struct CollectionBehaviorTests {
    @Test("加载卡片不能重复打开衣物")
    func loadingCardCannotOpenGarment() {
        #expect(!YISUGarmentCardPolicy.canOpen(state: .loading))
    }

    @Test("正常与按下卡片可以打开衣物", arguments: [
        YISUGarmentCardState.normal,
        .pressed,
        .imageError
    ])
    func availableCardsCanOpenGarment(_ state: YISUGarmentCardState) {
        #expect(YISUGarmentCardPolicy.canOpen(state: state))
    }

    @Test("底部导航保持三个固定入口")
    func bottomNavigationHasThreeOrderedTabs() {
        #expect(YISUTab.allCases == [.wardrobe, .addGarment, .profile])
        #expect(YISUTab.allCases.map(\.title) == ["衣橱", "添加衣物", "我的"])
    }
}
