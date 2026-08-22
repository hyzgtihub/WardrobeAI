import Testing
import SwiftUI
import UIKit
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

    @Test("核心颜色与 Gate B4 Hi-Fi Token 一致")
    func coreColorsMatchHiFiTokens() throws {
        try expectColor(YISUTheme.Color.background, hex: 0xF8F5FC)
        try expectColor(YISUTheme.Color.surface, hex: 0xFFFCFE)
        try expectColor(YISUTheme.Color.surfaceSubtle, hex: 0xF5EFE7)
        try expectColor(YISUTheme.Color.brand, hex: 0x8D7AB5)
        try expectColor(YISUTheme.Color.brandEmphasis, hex: 0x7D6AA5)
        try expectColor(YISUTheme.Color.brandSubtle, hex: 0xC9C0E8)
        try expectColor(YISUTheme.Color.navAccent, hex: 0x5E5275)
        try expectColor(YISUTheme.Color.textPrimary, hex: 0x3A3545)
        try expectColor(YISUTheme.Color.textSecondary, hex: 0x817A8B)
        try expectColor(YISUTheme.Color.border, hex: 0xDED8E8)
        try expectColor(YISUTheme.Color.danger, hex: 0xB85F68)
        try expectColor(YISUTheme.Color.dangerSubtle, hex: 0xFAE9EA)
    }

    private func expectColor(_ color: SwiftUI.Color, hex: UInt32) throws {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let converted = UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #expect(converted)
        #expect(abs(red - CGFloat((hex >> 16) & 0xFF) / 255) < 0.001)
        #expect(abs(green - CGFloat((hex >> 8) & 0xFF) / 255) < 0.001)
        #expect(abs(blue - CGFloat(hex & 0xFF) / 255) < 0.001)
        #expect(abs(alpha - 1) < 0.001)
    }
}
