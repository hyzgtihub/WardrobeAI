import SwiftUI

struct RootView: View {
    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-design-system-gallery") {
            DesignSystemGalleryView()
        } else {
            NavigationStack {
                SignInView()
            }
        }
    }
}
