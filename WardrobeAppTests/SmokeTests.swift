import Testing
@testable import YISU

struct SmokeTests {
    @Test("应用名称为衣序")
    func appNameIsYISU() {
        #expect(AppIdentity.displayName == "衣序")
    }
}
