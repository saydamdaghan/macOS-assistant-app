import SwiftUI

@main
struct AsistanApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .frame(minWidth: 1180, minHeight: 740)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            switch store.phase {
            case .launching:
                ProgressView().controlSize(.small)
            case .setup:
                SetupView()
            case .locked:
                TouchIDView()
            case .modeSelect:
                ModeSelectView()
            case .loading:
                ModeLoadingView()
            case .ready:
                if store.mode == .work {
                    WorkShell()
                } else {
                    StudentShell()
                }
            }
        }
        .tint(DS.ink)
        .task { await store.bootstrap() }
        .overlay(alignment: .top) {
            if let banner = store.banner {
                Text(banner)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(DS.redSoft)
                    .clipShape(Capsule())
                    .padding(.top, 18)
                    .onTapGesture { store.banner = nil }
            }
        }
    }
}
