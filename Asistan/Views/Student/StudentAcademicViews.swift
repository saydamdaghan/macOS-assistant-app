import SwiftUI
import Charts

struct GradesView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    StatCard(
                        title: "GNO",
                        value: store.gno.map { String(format: "%.2f", $0) } ?? "—",
                        delta: (store.gno ?? 0) >= 2 ? "Koşullu geçiş açık" : "GNO 2.00 altı",
                        deltaPositive: (store.gno ?? 0) >= 2,
                        icon: "chart.bar.fill",
                        tint: DS.purple,
                        soft: DS.purpleSoft
                    )
                    StatCard(title: "Ders", value: "\(store.courses.count)", delta: nil, deltaPositive: true, icon: "book.fill", tint: DS.blue, soft: DS.blueSoft)
                    StatCard(
                        title: "Geçer",
                        value: "\(passedCount)",
                        delta: nil,
                        deltaPositive: true,
                        icon: "checkmark.seal.fill",
                        tint: DS.green,
                        soft: DS.greenSoft
                    )
                }

                AsistanCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Gelişim")
                        Chart(series(), id: \.label) { row in
                            LineMark(x: .value("Dönem", row.label), y: .value("GNO", row.value))
                                .foregroundStyle(DS.blue)
                                .symbol(Circle())
                            AreaMark(x: .value("Dönem", row.label), y: .value("GNO", row.value))
                                .foregroundStyle(DS.blue.opacity(0.1))
                        }
                        .chartYScale(domain: 0...4)
                        .frame(height: 180)
                    }
                }

                AsistanCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "KKÜ harf notları")
                        HStack {
                            ForEach(KKULetter.allCases) { letter in
                                VStack(spacing: 4) {
                                    Text(letter.rawValue).font(.system(size: 12, weight: .bold))
                                    Text(letter.rangeLabel).font(.system(size: 10)).foregroundStyle(DS.muted)
                                    Text(String(format: "%.2f", letter.coefficient)).font(.system(size: 10)).foregroundStyle(DS.faint)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                AsistanCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Ders bazında")
                        ForEach(store.courses) { course in
                            let result = KKUGrading.result(
                                course: course,
                                assessments: store.assessments.filter { $0.courseId == course.id },
                                gno: store.gno ?? 0
                            )
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(course.name).font(.system(size: 13, weight: .semibold))
                                    Spacer()
                                    Text(result.letter?.rawValue ?? "—")
                                        .font(.system(size: 13, weight: .bold))
                                    Text(result.currentScore.map { String(format: "%.1f", $0) } ?? "")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DS.muted)
                                }
                                Text(KKUGrading.neededFinalText(result: result, gno: store.gno ?? 0))
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.blue)
                                if let letter = result.letter {
                                    Text(letter.resultLabel + (letter.isConditional ? " · GNO ≥ 2.00 gerekir" : ""))
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.muted)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        if store.courses.isEmpty {
                            EmptyHint(text: "Ders ve sınav notu ekleyince ortalama oluşur.")
                        }
                    }
                }
            }
            .padding(28)
        }
    }

    private var passedCount: Int {
        store.courses.filter { course in
            let result = KKUGrading.result(course: course, assessments: store.assessments.filter { $0.courseId == course.id }, gno: store.gno ?? 0)
            return result.letter?.isPass == true || ((store.gno ?? 0) >= 2 && result.letter?.isConditional == true)
        }.count
    }

    private func series() -> [(label: String, value: Double)] {
        let groups = Dictionary(grouping: store.courses, by: \.termKey)
        return groups.keys.sorted().compactMap { key in
            guard let avg = KKUGrading.termAverage(courses: groups[key] ?? [], assessments: store.assessments) else { return nil }
            return (key, avg)
        }
    }
}

struct AssignmentsView: View {
    @Environment(AppStore.self) private var store
    @State private var title = ""
    @State private var detail = ""
    @State private var courseId: UUID?
    @State private var due = Date()
    @State private var hasDue = true

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                AsistanCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SoftField(placeholder: "Ödev başlığı", text: $title)
                        SoftField(placeholder: "Detay", text: $detail)
                        HStack {
                            Picker("Ders", selection: $courseId) {
                                Text("Ders yok").tag(UUID?.none)
                                ForEach(store.courses) { course in
                                    Text(course.name).tag(Optional(course.id))
                                }
                            }
                            Toggle("Teslim", isOn: $hasDue).controlSize(.mini)
                            if hasDue { FormDateField(title: "", date: $due) }
                            PrimaryButton(title: "Ekle") {
                                guard !title.isEmpty else { return }
                                Task {
                                    await store.addAssignment(courseId: courseId, title: title, detail: detail, due: hasDue ? due : nil)
                                    title = ""; detail = ""
                                }
                            }
                        }
                    }
                }

                ForEach(store.assignments) { item in
                    AsistanCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).font(.system(size: 14, weight: .semibold))
                                Text([
                                    item.courseId.flatMap { id in store.courses.first { $0.id == id }?.name },
                                    Formatters.longDay(item.dueDate)
                                ].compactMap { $0 }.joined(separator: " · "))
                                .font(.system(size: 12))
                                .foregroundStyle(DS.muted)
                            }
                            Spacer()
                            Picker("", selection: Binding(
                                get: { item.status },
                                set: { new in Task { await store.setAssignmentStatus(item, status: new) } }
                            )) {
                                Text("Bekliyor").tag("bekliyor")
                                Text("Yapılıyor").tag("yapiliyor")
                                Text("Teslim").tag("teslim")
                                Text("Gecikti").tag("gecikti")
                            }
                            .frame(width: 140)
                        }
                    }
                }
                if store.assignments.isEmpty {
                    EmptyHint(text: "Ödevlerini buraya yaz. Teslim tarihi hatırlatılır.")
                }
            }
            .padding(28)
        }
    }
}

struct ScholarshipsView: View {
    @Environment(AppStore.self) private var store
    @State private var name = ""
    @State private var org = ""
    @State private var amount = ""
    @State private var notes = ""
    @State private var deadline = Date()
    @State private var hasDeadline = true

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                AsistanCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SoftField(placeholder: "Burs adı", text: $name)
                        SoftField(placeholder: "Kurum", text: $org)
                        HStack {
                            SoftField(placeholder: "Tutar", text: $amount)
                            Toggle("Son tarih", isOn: $hasDeadline).controlSize(.mini)
                            if hasDeadline { FormDateField(title: "", date: $deadline) }
                        }
                        SoftField(placeholder: "Not", text: $notes)
                        PrimaryButton(title: "Başvuru ekle") {
                            guard !name.isEmpty else { return }
                            Task {
                                await store.addScholarship(
                                    name: name,
                                    organization: org,
                                    amount: Double(amount.replacingOccurrences(of: ",", with: ".")),
                                    deadline: hasDeadline ? deadline : nil,
                                    notes: notes
                                )
                                name = ""; org = ""; amount = ""; notes = ""
                            }
                        }
                    }
                }

                ForEach(store.scholarships) { item in
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name).font(.system(size: 15, weight: .semibold))
                                    Text([item.organization, item.amount.map(Formatters.tryAmount), Formatters.longDay(item.deadline)].compactMap { $0 }.joined(separator: " · "))
                                        .font(.system(size: 12))
                                        .foregroundStyle(DS.muted)
                                }
                                Spacer()
                                StatusBadge(
                                    text: item.statusLabel,
                                    tint: color(item.status).0,
                                    soft: color(item.status).1
                                )
                            }
                            if let notes = item.notes, !notes.isEmpty {
                                Text(notes).font(.system(size: 12)).foregroundStyle(DS.muted)
                            }
                            HStack {
                                ForEach(["basvuru", "inceleme", "kabul", "red"], id: \.self) { status in
                                    GhostButton(title: label(status)) {
                                        Task { await store.setScholarshipStatus(item, status: status) }
                                    }
                                }
                            }
                        }
                    }
                }
                if store.scholarships.isEmpty {
                    EmptyHint(text: "Burs başvurularını ve durumlarını burada tut.")
                }
            }
            .padding(28)
        }
    }

    private func label(_ status: String) -> String {
        switch status {
        case "inceleme": return "İnceleme"
        case "kabul": return "Kabul"
        case "red": return "Red"
        default: return "Başvuru"
        }
    }

    private func color(_ status: String) -> (Color, Color) {
        switch status {
        case "kabul": return (DS.green, DS.greenSoft)
        case "red": return (DS.red, DS.redSoft)
        case "inceleme": return (DS.blue, DS.blueSoft)
        default: return (DS.orange, DS.orangeSoft)
        }
    }
}

struct LecturersView: View {
    @Environment(AppStore.self) private var store
    @State private var name = ""
    @State private var email = ""
    @State private var office = ""
    @State private var notes = ""
    @State private var selected: Lecturer?

    var body: some View {
        VStack(spacing: 0) {
            AsistanCard {
                HStack {
                    SoftField(placeholder: "Hoca adı", text: $name)
                    SoftField(placeholder: "E-posta", text: $email)
                    SoftField(placeholder: "Oda", text: $office)
                    PrimaryButton(title: "Ekle") {
                        guard !name.isEmpty else { return }
                        Task {
                            await store.addLecturer(name: name, email: email, office: office, notes: notes)
                            name = ""; email = ""; office = ""
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.lecturers) { item in
                        AsistanCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.name).font(.system(size: 15, weight: .semibold))
                                Text([item.email, item.office].compactMap { $0 }.joined(separator: " · "))
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.muted)
                                if let notes = item.notes, !notes.isEmpty {
                                    Text(notes).font(.system(size: 13)).foregroundStyle(DS.text)
                                }
                            }
                        }
                        .onTapGesture { selected = item }
                    }
                    if store.lecturers.isEmpty {
                        EmptyHint(text: "Hocalarla ilgili notlarını burada sakla.")
                    }
                }
                .padding(28)
            }
        }
        .sheet(item: $selected) { item in
            LecturerNoteSheet(lecturer: item)
        }
    }
}

struct LecturerNoteSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let lecturer: Lecturer
    @State private var notes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lecturer.name).font(.system(size: 18, weight: .semibold))
            TextEditor(text: $notes)
                .font(.system(size: 13))
                .frame(width: 400, height: 180)
            HStack {
                Spacer()
                GhostButton(title: "Vazgeç") { dismiss() }
                PrimaryButton(title: "Kaydet") {
                    Task { await store.updateLecturerNotes(lecturer, notes: notes); dismiss() }
                }
            }
        }
        .padding(22)
        .onAppear { notes = lecturer.notes ?? "" }
    }
}
