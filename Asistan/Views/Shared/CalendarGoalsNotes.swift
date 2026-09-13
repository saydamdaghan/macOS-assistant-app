import SwiftUI

struct CalendarPage: View {
    @Environment(AppStore.self) private var store
    let mode: AppMode
    @State private var month = Date()
    @State private var title = ""
    @State private var picked = Date()

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            AsistanCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button { month = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text(monthTitle)
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Button { month = Calendar.current.date(byAdding: .month, value: 1, to: month) ?? month } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(DS.text)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"], id: \.self) { d in
                            Text(d).font(.system(size: 11, weight: .medium)).foregroundStyle(DS.muted)
                        }
                        ForEach(days(), id: \.self) { day in
                            let key = DateTools.iso(day.date)
                            let marked = store.marks(for: mode).contains { $0.date == key }
                            VStack(spacing: 4) {
                                Text("\(Calendar.current.component(.day, from: day.date))")
                                    .font(.system(size: 12, weight: day.inMonth ? .medium : .regular))
                                    .foregroundStyle(day.inMonth ? DS.text : DS.faint)
                                Circle()
                                    .fill(marked ? DS.blue : Color.clear)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Calendar.current.isDateInToday(day.date) ? DS.blueSoft : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
            }

            VStack(spacing: 14) {
                AsistanCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "Yaklaşan")
                        ForEach(store.marks(for: mode).sorted { $0.date < $1.date }.prefix(10)) { item in
                            HStack {
                                Text(item.title).font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text(item.kind).font(.system(size: 11)).foregroundStyle(DS.muted)
                                Text(Formatters.day(item.date)).font(.system(size: 12)).foregroundStyle(DS.muted)
                            }
                        }
                        if store.marks(for: mode).isEmpty {
                            EmptyHint(text: "Bu ay işaretli bir tarih yok.")
                        }
                    }
                }
                AsistanCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "Etkinlik ekle")
                        SoftField(placeholder: "Başlık", text: $title)
                        FormDateField(title: "Tarih", date: $picked)
                        PrimaryButton(title: "Kaydet") {
                            guard !title.isEmpty else { return }
                            Task {
                                await store.addEvent(title: title, detail: "", date: picked)
                                title = ""
                            }
                        }
                    }
                }
            }
            .frame(width: 340)
        }
        .padding(28)
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: month)
    }

    private struct DayItem: Hashable {
        let date: Date
        let inMonth: Bool
    }

    private func days() -> [DayItem] {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
        let weekday = cal.component(.weekday, from: start)
        let mondayIndex = (weekday + 5) % 7
        let first = cal.date(byAdding: .day, value: -mondayIndex, to: start) ?? start
        return (0..<42).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: first) else { return nil }
            return DayItem(date: date, inMonth: cal.isDate(date, equalTo: month, toGranularity: .month))
        }
    }
}

struct GoalsView: View {
    @Environment(AppStore.self) private var store
    let mode: AppMode
    @State private var title = ""
    @State private var target = "100"
    @State private var deadline = Date()
    @State private var hasDeadline = false

    var items: [Goal] { mode == .work ? store.workGoals : store.studentGoals }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                AsistanCard {
                    HStack {
                        SoftField(placeholder: "Yeni hedef", text: $title)
                        TextField("Hedef", text: $target)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(DS.chip)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .frame(width: 80)
                        Toggle("Tarih", isOn: $hasDeadline).controlSize(.mini)
                        if hasDeadline { FormDateField(title: "", date: $deadline) }
                        PrimaryButton(title: "Ekle") {
                            guard !title.isEmpty else { return }
                            Task {
                                await store.addGoal(title: title, detail: "", target: Double(target) ?? 100, deadline: hasDeadline ? deadline : nil)
                                title = ""
                            }
                        }
                    }
                }

                ForEach(items) { goal in
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(goal.title).font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Text("\(Int(goal.progress))/\(Int(goal.target))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.muted)
                            }
                            ProgressView(value: goal.ratio).tint(mode == .work ? DS.purple : DS.blue)
                            HStack {
                                if let d = goal.deadline {
                                    Text(Formatters.longDay(d)).font(.system(size: 11)).foregroundStyle(DS.muted)
                                }
                                Spacer()
                                GhostButton(title: "+10") {
                                    Task { await store.setGoalProgress(goal, progress: min(goal.target, goal.progress + 10)) }
                                }
                            }
                        }
                    }
                }
                if items.isEmpty {
                    EmptyHint(text: "Hedeflerini buraya yaz. Widget olarak da masaüstüne eklenebilir.")
                }
            }
            .padding(28)
        }
    }
}

struct NotesView: View {
    @Environment(AppStore.self) private var store
    let mode: AppMode
    var forcedCategory: String? = nil
    @State private var title = ""
    @State private var content = ""
    @State private var category = "genel"
    @State private var selected: Note?

    var items: [Note] {
        let base = mode == .work ? store.workNotes : store.studentNotes
        if let forcedCategory {
            return base.filter { $0.category == forcedCategory }
        }
        return base
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 12) {
                AsistanCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SoftField(placeholder: "Başlık", text: $title)
                        if forcedCategory == nil && mode == .student {
                            Picker("Tür", selection: $category) {
                                Text("Genel").tag("genel")
                                Text("Ders").tag("ders")
                                Text("Hoca").tag("hoca")
                            }
                            .pickerStyle(.segmented)
                        }
                        TextEditor(text: $content)
                            .font(.system(size: 13))
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(DS.chip)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        PrimaryButton(title: "Kaydet") {
                            guard !title.isEmpty else { return }
                            Task {
                                await store.addNote(title: title, content: content, category: forcedCategory ?? category, related: nil)
                                title = ""; content = ""
                            }
                        }
                    }
                }
                Spacer()
            }
            .frame(width: 320)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(items) { note in
                        AsistanCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(note.title).font(.system(size: 14, weight: .semibold))
                                    Spacer()
                                    StatusBadge(text: note.categoryLabel, tint: DS.purple, soft: DS.purpleSoft)
                                }
                                Text(note.content)
                                    .font(.system(size: 13))
                                    .foregroundStyle(DS.muted)
                                    .lineLimit(6)
                            }
                        }
                        .onTapGesture { selected = note }
                    }
                    if items.isEmpty { EmptyHint(text: "Notların burada durur.") }
                }
            }
        }
        .padding(28)
        .sheet(item: $selected) { note in
            NoteEditorSheet(note: note)
        }
    }
}

struct NoteEditorSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let note: Note
    @State private var title = ""
    @State private var content = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoftField(placeholder: "Başlık", text: $title)
            TextEditor(text: $content)
                .font(.system(size: 13))
                .frame(width: 420, height: 220)
            HStack {
                GhostButton(title: "Sil") {
                    Task { await store.deleteNote(note); dismiss() }
                }
                Spacer()
                GhostButton(title: "Vazgeç") { dismiss() }
                PrimaryButton(title: "Kaydet") {
                    Task { await store.updateNote(note, title: title, content: content); dismiss() }
                }
            }
        }
        .padding(22)
        .onAppear {
            title = note.title
            content = note.content
        }
    }
}

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AsistanCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: "Profil")
                    SoftField(placeholder: "Ad", text: $name)
                    PrimaryButton(title: "Kaydet") {
                        Task { await store.updateDisplayName(name) }
                    }
                    Text("Giriş yalnızca Touch ID ile. Supabase anahtarları Keychain’de durur, repoya girmez.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.muted)
                }
            }
            AsistanCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: "Oturum")
                    HStack {
                        GhostButton(title: "Kilitle") { store.lock() }
                        GhostButton(title: "Mod seçimine dön") { store.phase = .modeSelect }
                        PrimaryButton(title: "Çıkış yap", fill: DS.red) {
                            Task { await store.signOut() }
                        }
                    }
                }
            }
            if store.mode == .student {
                AsistanCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "KKÜ")
                        Text("Kırıkkale Üniversitesi Öğrenci Bilgi Sistemi")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.muted)
                        PrimaryButton(title: "KKÜ Öğrenci Portalı", icon: "arrow.up.right") {
                            store.openKKUPortal()
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(28)
        .onAppear { name = store.displayName }
    }
}
