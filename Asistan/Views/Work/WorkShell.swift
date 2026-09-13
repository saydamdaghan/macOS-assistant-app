import SwiftUI

struct WorkShell: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        HStack(spacing: 0) {
            SidebarRail(
                tabs: WorkTab.allCases.map { ($0, $0.icon, $0.title) },
                selection: $store.selectedWork,
                name: store.displayName,
                onAvatar: { store.selectedWork = .settings }
            )
            VStack(spacing: 0) {
                if store.selectedWork == .home {
                    TopBar(
                        modeTitle: "İş Modu",
                        greeting: "\(Greeting.hello(name: store.displayName)) 👋",
                        subtitle: "İşler, ödemeler ve projeler tek yerde.",
                        search: $store.search
                    )
                } else {
                    PageHeader(title: store.selectedWork.title)
                }
                Group {
                    switch store.selectedWork {
                    case .home: WorkDashboardView()
                    case .jobs: JobsView()
                    case .projects: ProjectsView()
                    case .calendar: CalendarPage(mode: .work)
                    case .finance: FinanceView()
                    case .goals: GoalsView(mode: .work)
                    case .notes: NotesView(mode: .work)
                    case .settings: SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(DS.bg)
        }
    }
}
