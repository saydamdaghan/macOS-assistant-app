import Foundation
import Observation
import Supabase
import AppKit

@MainActor
@Observable
final class AppStore {
    var phase: AppPhase = .launching
    var mode: AppMode = .work
    var selectedWork: WorkTab = .home
    var selectedStudent: StudentTab = .home
    var search = ""
    var banner: String?
    var busy = false

    var profile: Profile?
    var jobs: [Job] = []
    var projects: [Project] = []
    var tasks: [TaskItem] = []
    var payments: [Payment] = []
    var goals: [Goal] = []
    var notes: [Note] = []
    var events: [CalendarEvent] = []
    var courses: [Course] = []
    var meetings: [CourseMeeting] = []
    var assessments: [Assessment] = []
    var assignments: [Assignment] = []
    var lecturers: [Lecturer] = []
    var scholarships: [Scholarship] = []

    @ObservationIgnored
    private var client: SupabaseClient?

    var displayName: String { profile?.displayName ?? "Kullanıcı" }
    var userId: UUID? { profile?.id }

    var workGoals: [Goal] { goals.filter { $0.mode == "work" } }
    var studentGoals: [Goal] { goals.filter { $0.mode == "student" } }
    var workNotes: [Note] { notes.filter { $0.mode == "work" } }
    var studentNotes: [Note] { notes.filter { $0.mode == "student" } }

    func bootstrap() async {
        if !KeychainStore.hasConfig {
            phase = .setup
            return
        }
        do {
            try makeClient()
            _ = try await client?.auth.session
            phase = .locked
        } catch {
            phase = .setup
        }
    }

    func completeSetup(url: String, anon: String, email: String, password: String, name: String, create: Bool) async {
        busy = true
        defer { busy = false }
        do {
            let cleanURL = try SupabaseConfig.normalizeURL(url)
            let cleanKey = anon.trimmingCharacters(in: .whitespacesAndNewlines)
            guard cleanKey.isEmpty == false else { throw SetupError.badKey }
            KeychainStore.saveConfig(url: cleanURL, anon: cleanKey)
            try makeClient()
            guard let client else { return }
            if create {
                let response = try await client.auth.signUp(email: email, password: password)
                if response.session == nil {
                    banner = "Hesap açıldı. Supabase Auth’ta e-posta doğrulamasını kapatıp “Var olan hesap” ile gir."
                    return
                }
            } else {
                try await client.auth.signIn(email: email, password: password)
            }
            _ = try await client.auth.session
            try await loadProfile(fallbackName: name)
            phase = .locked
        } catch {
            banner = SetupError.display(error)
        }
    }

    func unlock() async {
        do {
            try await BiometricService.unlock()
            await refresh()
            await NotificationService.requestPermission()
            phase = .modeSelect
        } catch {
            banner = error.localizedDescription
        }
    }

    func choose(_ newMode: AppMode) async {
        mode = newMode
        phase = .loading
        try? await Task.sleep(for: .milliseconds(1100))
        phase = .ready
    }

    func lock() {
        phase = .locked
    }

    func signOut() async {
        try? await client?.auth.signOut()
        KeychainStore.clearConfig()
        client = nil
        resetData()
        phase = .setup
    }

    func refresh() async {
        guard let client else { return }
        do {
            try await loadProfile(fallbackName: "Kullanıcı")
            async let j: [Job] = client.from("jobs").select().order("created_at", ascending: false).execute().value
            async let p: [Project] = client.from("projects").select().order("created_at", ascending: false).execute().value
            async let t: [TaskItem] = client.from("tasks").select().order("created_at", ascending: false).execute().value
            async let pay: [Payment] = client.from("payments").select().order("due_date", ascending: true).execute().value
            async let g: [Goal] = client.from("goals").select().order("created_at", ascending: false).execute().value
            async let n: [Note] = client.from("notes").select().order("updated_at", ascending: false).execute().value
            async let e: [CalendarEvent] = client.from("calendar_events").select().order("event_date", ascending: true).execute().value
            async let c: [Course] = client.from("courses").select().order("year", ascending: false).execute().value
            async let m: [CourseMeeting] = client.from("course_meetings").select().execute().value
            async let a: [Assessment] = client.from("assessments").select().order("exam_date", ascending: true).execute().value
            async let hw: [Assignment] = client.from("assignments").select().order("due_date", ascending: true).execute().value
            async let l: [Lecturer] = client.from("lecturers").select().order("name", ascending: true).execute().value
            async let s: [Scholarship] = client.from("scholarships").select().order("deadline", ascending: true).execute().value

            jobs = try await j
            projects = try await p
            tasks = try await t
            payments = try await pay
            goals = try await g
            notes = try await n
            events = try await e
            courses = try await c
            meetings = try await m
            assessments = try await a
            assignments = try await hw
            lecturers = try await l
            scholarships = try await s

            publishWidgets()
            await NotificationService.rebuild(
                payments: payments,
                tasks: tasks,
                assignments: assignments,
                assessments: assessments,
                scholarships: scholarships,
                events: events,
                jobs: jobs,
                courses: courses
            )
        } catch {
            banner = error.localizedDescription
        }
    }

    func updateDisplayName(_ name: String) async {
        guard let id = userId, let client else { return }
        do {
            try await client.from("profiles").update(["display_name": name]).eq("id", value: id).execute()
            profile?.displayName = name
        } catch {
            banner = error.localizedDescription
        }
    }

    // MARK: Work

    func addJob(title: String, clientName: String, detail: String) async {
        guard let userId, let client else { return }
        let row = JobWrite(user_id: userId, title: title, client: emptyNil(clientName), description: emptyNil(detail), status: "aktif")
        do {
            try await client.from("jobs").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func setJobStatus(_ job: Job, status: String) async {
        do {
            try await client?.from("jobs").update(["status": status]).eq("id", value: job.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func deleteJob(_ job: Job) async {
        do {
            try await client?.from("jobs").delete().eq("id", value: job.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func addPayment(jobId: UUID, title: String, amount: Double, due: Date) async {
        guard let userId, let client else { return }
        let row = PaymentWrite(
            user_id: userId,
            job_id: jobId,
            title: emptyNil(title),
            amount: amount,
            due_date: DateTools.iso(due),
            status: "bekliyor"
        )
        do {
            try await client.from("payments").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func confirmPayment(_ payment: Payment) async {
        struct Patch: Encodable {
            let status: String
            let paid_at: String
        }
        let patch = Patch(status: "odendi", paid_at: ISO8601DateFormatter().string(from: Date()))
        do {
            try await client?.from("payments").update(patch).eq("id", value: payment.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func addTask(projectId: UUID, title: String, priority: String, due: Date?) async {
        guard let userId, let client else { return }
        let row = TaskWrite(
            user_id: userId,
            project_id: projectId,
            title: title,
            status: "bekliyor",
            priority: priority,
            due_date: due.map(DateTools.iso)
        )
        do {
            try await client.from("tasks").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func toggleTask(_ task: TaskItem) async {
        let next = task.isDone ? "bekliyor" : "bitti"
        do {
            try await client?.from("tasks").update(["status": next]).eq("id", value: task.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func deleteTask(_ task: TaskItem) async {
        do {
            try await client?.from("tasks").delete().eq("id", value: task.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func project(for job: Job) -> Project? {
        projects.first { $0.jobId == job.id }
    }

    func tasks(for project: Project) -> [TaskItem] {
        tasks.filter { $0.projectId == project.id }
    }

    func payments(for job: Job) -> [Payment] {
        payments.filter { $0.jobId == job.id }
    }

    // MARK: Shared

    func addGoal(title: String, detail: String, target: Double, deadline: Date?) async {
        guard let userId, let client else { return }
        let row = GoalWrite(
            user_id: userId,
            mode: mode.rawValue,
            title: title,
            detail: emptyNil(detail),
            progress: 0,
            target: target,
            deadline: deadline.map(DateTools.iso)
        )
        do {
            try await client.from("goals").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func setGoalProgress(_ goal: Goal, progress: Double) async {
        do {
            try await client?.from("goals").update(["progress": progress]).eq("id", value: goal.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func addNote(title: String, content: String, category: String, related: UUID?) async {
        guard let userId, let client else { return }
        let row = NoteWrite(
            user_id: userId,
            mode: mode.rawValue,
            title: title,
            content: content,
            category: category,
            related_id: related
        )
        do {
            try await client.from("notes").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func updateNote(_ note: Note, title: String, content: String) async {
        struct Patch: Encodable {
            let title: String
            let content: String
        }
        do {
            try await client?.from("notes").update(Patch(title: title, content: content)).eq("id", value: note.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func deleteNote(_ note: Note) async {
        do {
            try await client?.from("notes").delete().eq("id", value: note.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func addEvent(title: String, detail: String, date: Date) async {
        guard let userId, let client else { return }
        let row = EventWrite(
            user_id: userId,
            mode: mode.rawValue,
            title: title,
            detail: emptyNil(detail),
            event_date: DateTools.iso(date)
        )
        do {
            try await client.from("calendar_events").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    // MARK: Student

    func addCourse(code: String, name: String, credits: Double, semester: String, year: Int, instructor: String, mid: Double, fin: Double) async {
        guard let userId, let client else { return }
        let row = CourseWrite(
            user_id: userId,
            code: emptyNil(code),
            name: name,
            credits: credits,
            semester: semester,
            year: year,
            instructor: emptyNil(instructor),
            midterm_weight: mid,
            final_weight: fin
        )
        do {
            try await client.from("courses").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func addMeeting(courseId: UUID, day: Int, start: String, end: String, location: String) async {
        guard let userId, let client else { return }
        let row = MeetingWrite(
            user_id: userId,
            course_id: courseId,
            day_of_week: day,
            start_time: start,
            end_time: end,
            location: emptyNil(location)
        )
        do {
            try await client.from("course_meetings").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func addAssessment(courseId: UUID, kind: String, name: String, score: Double?, weight: Double, date: Date?) async {
        guard let userId, let client else { return }
        let row = AssessmentWrite(
            user_id: userId,
            course_id: courseId,
            kind: kind,
            name: name,
            score: score,
            max_score: 100,
            weight: weight,
            exam_date: date.map(DateTools.iso)
        )
        do {
            try await client.from("assessments").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func addAssignment(courseId: UUID?, title: String, detail: String, due: Date?) async {
        guard let userId, let client else { return }
        let row = AssignmentWrite(
            user_id: userId,
            course_id: courseId,
            title: title,
            detail: emptyNil(detail),
            due_date: due.map(DateTools.iso),
            status: "bekliyor"
        )
        do {
            try await client.from("assignments").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func setAssignmentStatus(_ item: Assignment, status: String) async {
        do {
            try await client?.from("assignments").update(["status": status]).eq("id", value: item.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func addLecturer(name: String, email: String, office: String, notes: String) async {
        guard let userId, let client else { return }
        let row = LecturerWrite(user_id: userId, name: name, email: emptyNil(email), office: emptyNil(office), notes: emptyNil(notes))
        do {
            try await client.from("lecturers").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func updateLecturerNotes(_ lecturer: Lecturer, notes: String) async {
        do {
            try await client?.from("lecturers").update(["notes": notes]).eq("id", value: lecturer.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func addScholarship(name: String, organization: String, amount: Double?, deadline: Date?, notes: String) async {
        guard let userId, let client else { return }
        let row = ScholarshipWrite(
            user_id: userId,
            name: name,
            organization: emptyNil(organization),
            amount: amount,
            deadline: deadline.map(DateTools.iso),
            status: "basvuru",
            notes: emptyNil(notes)
        )
        do {
            try await client.from("scholarships").insert(row).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func setScholarshipStatus(_ item: Scholarship, status: String) async {
        do {
            try await client?.from("scholarships").update(["status": status]).eq("id", value: item.id).execute()
            await refresh()
        } catch { banner = error.localizedDescription }
    }

    func openKKUPortal() {
        if let url = URL(string: "https://obs.kku.edu.tr/") {
            NSWorkspace.shared.open(url)
        }
    }

    func marks(for mode: AppMode) -> [CalendarMark] {
        var items: [CalendarMark] = []
        if mode == .work {
            for payment in payments where payment.status != "odendi" {
                if let d = payment.dueDate {
                    items.append(.init(id: "p-\(payment.id)", date: d, title: payment.title ?? "Ödeme", kind: "ödeme"))
                }
            }
            for task in tasks where !task.isDone {
                if let d = task.dueDate {
                    items.append(.init(id: "t-\(task.id)", date: d, title: task.title, kind: "görev"))
                }
            }
        } else {
            for hw in assignments where hw.status != "teslim" {
                if let d = hw.dueDate {
                    items.append(.init(id: "h-\(hw.id)", date: d, title: hw.title, kind: "ödev"))
                }
            }
            for exam in assessments {
                if let d = exam.examDate {
                    items.append(.init(id: "e-\(exam.id)", date: d, title: exam.name, kind: "sınav"))
                }
            }
            for sch in scholarships {
                if let d = sch.deadline {
                    items.append(.init(id: "s-\(sch.id)", date: d, title: sch.name, kind: "burs"))
                }
            }
        }
        for event in events where event.mode == mode.rawValue {
            items.append(.init(id: "c-\(event.id)", date: event.eventDate, title: event.title, kind: "etkinlik"))
        }
        return items
    }

    var monthIncome: Double {
        let cal = Calendar.current
        return payments
            .filter { $0.status == "odendi" && $0.paidAt.map { cal.isDate($0, equalTo: Date(), toGranularity: .month) } == true }
            .reduce(0) { $0 + $1.amount }
    }

    var pendingIncome: Double {
        payments.filter { $0.resolvedStatus != "odendi" }.reduce(0) { $0 + $1.amount }
    }

    var gno: Double? {
        KKUGrading.termAverage(courses: courses, assessments: assessments)
    }

    var currentTermCourses: [Course] {
        guard let latest = courses.max(by: { ($0.year, $0.semester) < ($1.year, $1.semester) }) else { return courses }
        return courses.filter { $0.year == latest.year && $0.semester == latest.semester }
    }

    private func makeClient() throws {
        guard let urlString = KeychainStore.url, let key = KeychainStore.anon else {
            throw SetupError.badURL
        }
        let clean = try SupabaseConfig.normalizeURL(urlString)
        guard let url = URL(string: clean) else { throw SetupError.badURL }
        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    private func loadProfile(fallbackName: String) async throws {
        guard let client else { return }
        let session = try await client.auth.session
        let rows: [Profile] = try await client.from("profiles").select().eq("id", value: session.user.id).execute().value
        if let first = rows.first {
            profile = first
        } else {
            struct ProfileInsert: Encodable {
                let id: UUID
                let display_name: String
            }
            try await client.from("profiles").insert(ProfileInsert(id: session.user.id, display_name: fallbackName)).execute()
            profile = Profile(id: session.user.id, displayName: fallbackName, createdAt: Date(), updatedAt: Date())
        }
    }

    private func publishWidgets() {
        WidgetBridgeWriter.publish(name: displayName, tasks: tasks, projects: projects, goals: goals)
    }

    private func resetData() {
        profile = nil
        jobs = []; projects = []; tasks = []; payments = []
        goals = []; notes = []; events = []
        courses = []; meetings = []; assessments = []
        assignments = []; lecturers = []; scholarships = []
    }

    private func emptyNil(_ value: String) -> String? {
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

enum WorkTab: String, CaseIterable, Identifiable {
    case home, jobs, projects, calendar, finance, goals, notes, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Ana Sayfa"
        case .jobs: return "İşler"
        case .projects: return "Projeler"
        case .calendar: return "Takvim"
        case .finance: return "Finans"
        case .goals: return "Hedefler"
        case .notes: return "Notlar"
        case .settings: return "Ayarlar"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .jobs: return "briefcase"
        case .projects: return "square.grid.2x2"
        case .calendar: return "calendar"
        case .finance: return "chart.bar"
        case .goals: return "flag"
        case .notes: return "note.text"
        case .settings: return "gearshape"
        }
    }
}

enum StudentTab: String, CaseIterable, Identifiable {
    case home, courses, schedule, assignments, grades, scholarships, lecturers, calendar, goals, notes, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Ana Sayfa"
        case .courses: return "Dersler"
        case .schedule: return "Program"
        case .assignments: return "Ödevler"
        case .grades: return "Notlar"
        case .scholarships: return "Burslar"
        case .lecturers: return "Hocalar"
        case .calendar: return "Takvim"
        case .goals: return "Hedefler"
        case .notes: return "Defter"
        case .settings: return "Ayarlar"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .courses: return "book"
        case .schedule: return "calendar.badge.clock"
        case .assignments: return "checkmark.rectangle"
        case .grades: return "chart.xyaxis.line"
        case .scholarships: return "banknote"
        case .lecturers: return "person.2"
        case .calendar: return "calendar"
        case .goals: return "flag"
        case .notes: return "note.text"
        case .settings: return "gearshape"
        }
    }
}

enum SetupError: LocalizedError {
    case badURL
    case badKey

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Project URL yanlış. Settings → API’den https://xxxx.supabase.co kopyala. Sonda / veya dashboard linki olmasın."
        case .badKey:
            return "anon / publishable key boş. Aynı API sayfasından anon key’i yapıştır. service_role kullanma."
        }
    }

    static func display(_ error: Error) -> String {
        if let setup = error as? SetupError { return setup.localizedDescription }
        let text = error.localizedDescription
        if text.localizedCaseInsensitiveContains("invalid path") {
            return "Project URL hatalı. Tam olarak https://xxxx.supabase.co olmalı — dashboard linki, /rest/v1 veya sondaki / olmasın."
        }
        return text
    }
}

enum SupabaseConfig {
    static func normalizeURL(_ raw: String) throws -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = value.range(of: #"https://[a-z0-9]+\.supabase\.co"#, options: .regularExpression) {
            value = String(value[match])
        }
        while value.hasSuffix("/") {
            value.removeLast()
        }
        for suffix in ["/rest/v1", "/auth/v1", "/storage/v1", "/functions/v1"] {
            if value.lowercased().hasSuffix(suffix) {
                value.removeLast(suffix.count)
            }
        }
        guard
            let url = URL(string: value),
            url.scheme == "https",
            let host = url.host,
            host.hasSuffix(".supabase.co"),
            url.path.isEmpty || url.path == "/"
        else {
            throw SetupError.badURL
        }
        return "https://\(host)"
    }
}

struct JobWrite: Encodable {
    let user_id: UUID
    let title: String
    let client: String?
    let description: String?
    let status: String
}

struct PaymentWrite: Encodable {
    let user_id: UUID
    let job_id: UUID
    let title: String?
    let amount: Double
    let due_date: String
    let status: String
}

struct TaskWrite: Encodable {
    let user_id: UUID
    let project_id: UUID
    let title: String
    let status: String
    let priority: String
    let due_date: String?
}

struct GoalWrite: Encodable {
    let user_id: UUID
    let mode: String
    let title: String
    let detail: String?
    let progress: Double
    let target: Double
    let deadline: String?
}

struct NoteWrite: Encodable {
    let user_id: UUID
    let mode: String
    let title: String
    let content: String
    let category: String
    let related_id: UUID?
}

struct EventWrite: Encodable {
    let user_id: UUID
    let mode: String
    let title: String
    let detail: String?
    let event_date: String
}

struct CourseWrite: Encodable {
    let user_id: UUID
    let code: String?
    let name: String
    let credits: Double
    let semester: String
    let year: Int
    let instructor: String?
    let midterm_weight: Double
    let final_weight: Double
}

struct MeetingWrite: Encodable {
    let user_id: UUID
    let course_id: UUID
    let day_of_week: Int
    let start_time: String
    let end_time: String
    let location: String?
}

struct AssessmentWrite: Encodable {
    let user_id: UUID
    let course_id: UUID
    let kind: String
    let name: String
    let score: Double?
    let max_score: Double
    let weight: Double
    let exam_date: String?
}

struct AssignmentWrite: Encodable {
    let user_id: UUID
    let course_id: UUID?
    let title: String
    let detail: String?
    let due_date: String?
    let status: String
}

struct LecturerWrite: Encodable {
    let user_id: UUID
    let name: String
    let email: String?
    let office: String?
    let notes: String?
}

struct ScholarshipWrite: Encodable {
    let user_id: UUID
    let name: String
    let organization: String?
    let amount: Double?
    let deadline: String?
    let status: String
    let notes: String?
}
