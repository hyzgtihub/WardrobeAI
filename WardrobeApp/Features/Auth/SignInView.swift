import AuthenticationServices
import SwiftUI

struct SignInView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "hanger")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(AppIdentity.displayName)
                .font(.largeTitle.bold())
                .padding(.top, 20)

            Text("让每件衣服，都井然有序")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()

            SignInWithAppleButton(.continue) { _ in
                // Apple 登录将在认证功能阶段接入 nonce 与服务端会话。
            } onCompletion: { _ in
                // 工程骨架阶段仅验证系统控件与无障碍入口。
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .accessibilityIdentifier("auth.signInWithApple")

            Text("继续即表示你同意服务条款与隐私政策")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }
}

#Preview {
    SignInView()
}
