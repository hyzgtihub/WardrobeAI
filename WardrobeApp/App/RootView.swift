import SwiftUI

struct RootView: View {
    @State private var route: AppRoute
    @State private var setupState: WardrobeSetupState
    @State private var garments = WardrobeSampleData.garments
    @State private var selectedGarment = GarmentDetailDraft.whiteLinenShirt

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let screen = Self.argument(after: "-ui-screen", in: arguments)
        let stateValue = Self.argument(after: "-ui-state", in: arguments)
        let initialRoute: AppRoute = switch screen {
        case "onboarding": .onboarding
        case "wardrobe": .wardrobe
        case "garment-detail": .garmentDetail
        default: .signIn
        }
        _route = State(initialValue: initialRoute)
        _setupState = State(initialValue: WardrobeSetupState(rawValue: stateValue ?? "") ?? .creating)
    }

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-design-system-gallery") {
            DesignSystemGalleryView()
        } else {
            NavigationStack {
                switch route {
                case .signIn:
                    SignInView(onRegister: { route = .signUp }, onSubmit: { _, _ in route = .wardrobe })
                case .signUp:
                    SignUpView(onBack: { route = .signIn }, onCreated: { _, _ in route = .wardrobe })
                case .onboarding:
                    WardrobeSetupView(
                        state: setupState,
                        onRetry: { setupState = setupState == .currentRoleFailed ? .loadingCurrentRole : .creating },
                        onContinue: {
                            if setupState == .created { setupState = .currentRole }
                            else if setupState == .currentRole { route = .wardrobe }
                        }
                    )
                case .wardrobe:
                    WardrobeHomeView(
                        items: garments,
                        onSelectGarment: { garment in
                            if garment.id == GarmentDetailDraft.whiteLinenShirt.id {
                                selectedGarment = .whiteLinenShirt
                                route = .garmentDetail
                            }
                        }
                    )
                case .garmentDetail:
                    GarmentDetailView(
                        garment: selectedGarment,
                        onBack: { route = .wardrobe },
                        onChange: { updated in
                            selectedGarment = updated
                            if let index = garments.firstIndex(where: { $0.id == updated.id }) {
                                garments[index] = updated.summary
                            }
                        },
                        onDelete: { route = .wardrobe }
                    )
                }
            }
        }
    }

    private static func argument(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
