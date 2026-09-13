import SwiftUI

struct StudentShell: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        HStack(spacing: 0) {
            SidebarRail(
                tabs: StudentTab.allCases.map { ($0, $0.icon, $0.title) },
                selection: $store.selectedStudent,
                name: store.displayName,
                onAvatar: { store.selectedStudent = .settings }
            )
            VStack(spacing: 0) {
                if store.selectedStudent == .home {
                    TopBar(
                        modeTitle: "Öğrenci Modu",
                        greeting: "\(Greeting.hello(name: store.displayName)) 👋",
                        subtitle: "Kırıkkale Üniversitesi · Bilgisayar Mühendisliği",
                        search: $store.search
                    )
                } else {
                    PageHeader(
                        title: store.selectedStudent.title,
                        trailing: AnyView(
                            PrimaryButton(title: "KKÜ OBS", icon: "arrow.up.right") {
                                store.openKKUPortal()
                            }
                        )
                    )
                }
                Group {
                    switch store.selectedStudent {
                    case .home: StudentDashboardView()
                    case .courses: CoursesView()
                    case .schedule: ScheduleView()
                    case .assignments: AssignmentsView()
                    case .grades: GradesView()
                    case .scholarships: ScholarshipsView()
                    case .lecturers: LecturersView()
                    case .calendar: CalendarPage(mode: .student)
                    case .goals: GoalsView(mode: .student)
                    case .notes: NotesView(mode: .student)
                    case .settings: SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(DS.bg)
        }
    }
}
