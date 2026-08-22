import SwiftUI

enum YISUTheme {
    enum Color {
        static let background = SwiftUI.Color(red: 0.984, green: 0.969, blue: 0.937)
        static let surface = SwiftUI.Color(red: 1.000, green: 0.988, blue: 0.969)
        static let surfaceSubtle = SwiftUI.Color(red: 0.949, green: 0.925, blue: 0.875)
        static let brand = SwiftUI.Color(red: 0.616, green: 0.722, blue: 0.651)
        static let brandEmphasis = SwiftUI.Color(red: 0.365, green: 0.506, blue: 0.420)
        static let brandSubtle = SwiftUI.Color(red: 0.890, green: 0.929, blue: 0.902)
        static let textPrimary = SwiftUI.Color(red: 0.204, green: 0.204, blue: 0.271)
        static let textSecondary = SwiftUI.Color(red: 0.451, green: 0.447, blue: 0.529)
        static let textOnBrand = SwiftUI.Color.white
        static let border = SwiftUI.Color(red: 0.894, green: 0.871, blue: 0.827)
        static let danger = SwiftUI.Color(red: 0.753, green: 0.263, blue: 0.314)
        static let dangerSubtle = SwiftUI.Color(red: 0.980, green: 0.894, blue: 0.902)
        static let lavender = SwiftUI.Color(red: 0.725, green: 0.682, blue: 0.847)
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
