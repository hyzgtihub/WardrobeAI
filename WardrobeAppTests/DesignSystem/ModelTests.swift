import Foundation
import Testing
@testable import YISU

struct ModelTests {
    @Test("分类顺序与 Gate B4 一致")
    func categoryOrderMatchesGateB4() {
        #expect(YISUCategory.allCases.map(\.title) == [
            "全部", "上衣", "裤子", "外套", "裙子", "鞋子", "配饰", "其他"
        ])
    }

    @Test(arguments: [YISUControlState.disabled, .loading])
    func inactiveControlStatesRejectActions(_ state: YISUControlState) {
        #expect(!state.isInteractive)
    }

    @Test("正常与按下状态允许交互", arguments: [YISUControlState.normal, .pressed])
    func activeControlStatesAllowActions(_ state: YISUControlState) {
        #expect(state.isInteractive)
    }

    @Test("衣物摘要仅承载展示数据")
    func garmentSummaryKeepsPresentationDataOnly() {
        let item = GarmentSummary(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444401")!,
            title: "白色亚麻衬衫",
            metadata: "春夏 · 上衣",
            imagePath: nil,
            category: .tops
        )

        #expect(item.title == "白色亚麻衬衫")
        #expect(item.imagePath == nil)
        #expect(item.category == .tops)
    }
}
