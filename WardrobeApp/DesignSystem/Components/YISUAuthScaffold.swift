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
            YISULogoMark(animated: true)
                .frame(width: 104, height: 104)

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

struct YISULogoMark: View {
    var animated = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDrawn = false

    var body: some View {
        GeometryReader { proxy in
            let lineWidth = max(1.5, min(proxy.size.width, proxy.size.height) * 0.03125)

            ZStack {
                YISULogoHook()
                    .trim(from: 0, to: progress)
                    .stroke(YISUTheme.Color.navAccent, style: strokeStyle(lineWidth: lineWidth))
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.24), value: isDrawn)

                YISULogoBody()
                    .trim(from: 0, to: progress)
                    .stroke(YISUTheme.Color.navAccent, style: strokeStyle(lineWidth: lineWidth))
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.52).delay(0.10), value: isDrawn)

                YISULogoCollar()
                    .trim(from: 0, to: progress)
                    .stroke(YISUTheme.Color.brand, style: strokeStyle(lineWidth: lineWidth))
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.30).delay(0.56), value: isDrawn)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(animated && !reduceMotion && !isDrawn ? 0.988 : 1)
        .animation(.timingCurve(0.34, 1.32, 0.64, 1, duration: 0.10).delay(0.86), value: isDrawn)
        .accessibilityRepresentation {
            Image(systemName: "hanger")
                .accessibilityLabel("衣序品牌标志")
                .accessibilityIdentifier("brand.logo")
        }
        .onAppear {
            isDrawn = !animated || reduceMotion
            if animated && !reduceMotion {
                isDrawn = true
            }
        }
    }

    private var progress: CGFloat {
        !animated || reduceMotion || isDrawn ? 1 : 0
    }

    private func strokeStyle(lineWidth: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
    }
}

private protocol YISULogoShape: Shape {}

private extension YISULogoShape {
    func fitted(_ source: Path, in rect: CGRect) -> Path {
        source.applying(CGAffineTransform(scaleX: rect.width / 256, y: rect.height / 256))
    }
}

private struct YISULogoHook: YISULogoShape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 128, y: 118))
        path.addLine(to: CGPoint(x: 128, y: 106))
        path.addCurve(to: CGPoint(x: 137, y: 98), control1: CGPoint(x: 128, y: 101), control2: CGPoint(x: 132, y: 98))
        path.addLine(to: CGPoint(x: 139, y: 98))
        path.addCurve(to: CGPoint(x: 148, y: 89), control1: CGPoint(x: 144, y: 98), control2: CGPoint(x: 148, y: 94))
        path.addCurve(to: CGPoint(x: 139, y: 80), control1: CGPoint(x: 148, y: 84), control2: CGPoint(x: 144, y: 80))
        path.addCurve(to: CGPoint(x: 130, y: 89), control1: CGPoint(x: 134, y: 80), control2: CGPoint(x: 130, y: 84))
        return fitted(path, in: rect)
    }
}

private struct YISULogoBody: YISULogoShape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 128, y: 118))
        path.addLine(to: CGPoint(x: 70, y: 153))
        path.addCurve(to: CGPoint(x: 76, y: 178), control1: CGPoint(x: 58, y: 160), control2: CGPoint(x: 63, y: 178))
        path.addLine(to: CGPoint(x: 180, y: 178))
        path.addCurve(to: CGPoint(x: 186, y: 153), control1: CGPoint(x: 193, y: 178), control2: CGPoint(x: 198, y: 160))
        path.closeSubpath()
        return fitted(path, in: rect)
    }
}

private struct YISULogoCollar: YISULogoShape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 101, y: 151))
        path.addLine(to: CGPoint(x: 119, y: 141))
        path.addLine(to: CGPoint(x: 128, y: 159))
        path.addLine(to: CGPoint(x: 137, y: 141))
        path.addLine(to: CGPoint(x: 155, y: 151))
        return fitted(path, in: rect)
    }
}
