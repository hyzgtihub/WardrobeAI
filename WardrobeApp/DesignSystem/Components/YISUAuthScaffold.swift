import SwiftUI

struct YISUAuthScaffold<Content: View>: View {
    let showsBrandHeader: Bool
    @ViewBuilder let content: Content

    init(showsBrandHeader: Bool = true, @ViewBuilder content: () -> Content) {
        self.showsBrandHeader = showsBrandHeader
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: YISUTheme.Spacing.lg) {
                if showsBrandHeader {
                    brandHeader
                }
                content
            }
            .frame(maxWidth: 390)
            .padding(.horizontal, 20)
            .padding(.top, 48)
            .padding(.bottom, YISUTheme.Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(background)
    }

    private var brandHeader: some View {
        VStack(spacing: YISUTheme.Spacing.sm) {
            Text("衣序")
                .font(YISUTheme.Typography.title)
                .foregroundStyle(YISUTheme.Color.brand)
                .frame(width: 88, height: 88)
                .background(YISUTheme.Color.surface)
                .clipShape(Circle())
                .shadow(color: YISUTheme.Shadow.color, radius: 22, y: 7)

            Text("衣序 YISU")
                .font(YISUTheme.Typography.largeTitle)
                .foregroundStyle(YISUTheme.Color.textPrimary)
                .padding(.top, YISUTheme.Spacing.sm)

            Text("让每件衣服，都井然有序")
                .font(YISUTheme.Typography.callout)
                .foregroundStyle(YISUTheme.Color.textSecondary)
        }
    }

    private var background: some View {
        ZStack {
            YISUTheme.Color.background
            Circle()
                .fill(YISUTheme.Color.brandSubtle.opacity(0.42))
                .frame(width: 310, height: 310)
                .blur(radius: 48)
                .offset(x: 150, y: -300)
            Circle()
                .fill(YISUTheme.Color.dangerSubtle.opacity(0.7))
                .frame(width: 250, height: 250)
                .blur(radius: 52)
                .offset(x: -155, y: 320)
        }
        .ignoresSafeArea()
    }
}
