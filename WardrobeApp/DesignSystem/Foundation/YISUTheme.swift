import SwiftUI

enum YISUTheme {
    enum Color {
        static let background = SwiftUI.Color(red: 248 / 255, green: 245 / 255, blue: 252 / 255)
        static let surface = SwiftUI.Color(red: 255 / 255, green: 252 / 255, blue: 254 / 255)
        static let surfaceSubtle = SwiftUI.Color(red: 245 / 255, green: 239 / 255, blue: 231 / 255)
        static let brand = SwiftUI.Color(red: 141 / 255, green: 122 / 255, blue: 181 / 255)
        static let brandEmphasis = SwiftUI.Color(red: 125 / 255, green: 106 / 255, blue: 165 / 255)
        static let brandSubtle = SwiftUI.Color(red: 201 / 255, green: 192 / 255, blue: 232 / 255)
        static let navAccent = SwiftUI.Color(red: 94 / 255, green: 82 / 255, blue: 117 / 255)
        static let textPrimary = SwiftUI.Color(red: 58 / 255, green: 53 / 255, blue: 69 / 255)
        static let textSecondary = SwiftUI.Color(red: 129 / 255, green: 122 / 255, blue: 139 / 255)
        static let textOnBrand = SwiftUI.Color.white
        static let border = SwiftUI.Color(red: 222 / 255, green: 216 / 255, blue: 232 / 255)
        static let danger = SwiftUI.Color(red: 184 / 255, green: 95 / 255, blue: 104 / 255)
        static let dangerSubtle = SwiftUI.Color(red: 250 / 255, green: 233 / 255, blue: 234 / 255)
        static let lavender = SwiftUI.Color(red: 238 / 255, green: 234 / 255, blue: 247 / 255)
    }

    enum Typography {
        static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
    }

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let screen: CGFloat = 32
        static let capsule: CGFloat = 999
    }

    enum Shadow {
        static let color = SwiftUI.Color.black.opacity(0.08)
        static let radius: CGFloat = 16
        static let y: CGFloat = 8
    }

    enum Size {
        static let minimumTouchTarget: CGFloat = 44
        static let buttonHeight: CGFloat = 56
        static let bottomNavigationHeight: CGFloat = 67
    }

    enum Layout {
        static func isAccessibleTouchTarget(width: CGFloat, height: CGFloat) -> Bool {
            width >= Size.minimumTouchTarget && height >= Size.minimumTouchTarget
        }
    }
}
