import SwiftUI

struct CoursesView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false
    @State private var selected: Course?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                PrimaryButton(title: "Ders ekle", icon: "plus") { showAdd = true }
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.courses) { course in
                        let related = store.assessments.filter { $0.courseId == course.id }
                        let result = KKUGrading.result(course: course, assessments: related, gno: store.gno ?? 0)
                        AsistanCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(course.name).font(.system(size: 15, weight: .semibold))
                                    Text([course.code, course.instructor, "\(course.year) \(course.semester)", "\(course.credits) kredi"].compactMap { $0 }.joined(separator: " · "))
                                        .font(.system(size: 12))
                                        .foregroundStyle(DS.muted)
                                }
                                Spacer()
                                if let letter = result.letter {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(letter.rawValue)
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                        Text(result.currentScore.map { String(format: "%.1f", $0) } ?? "—")
                                            .font(.system(size: 11))
                                            .foregroundStyle(DS.muted)
                                    }
                                } else {
                                    Text("Not yok").font(.system(size: 12)).foregroundStyle(DS.muted)
                                }
                            }
                        }
                        .onTapGesture { selected = course }
                    }
                    if store.courses.isEmpty {
                        EmptyHint(text: "Dönem derslerini ekle.")
                    }
                }
                .padding(28)
            }
        }
        .sheet(isPresented: $showAdd) { AddCourseSheet() }
        .sheet(item: $selected) { course in CourseDetailSheet(course: course) }
    }
}

struct AddCourseSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var name = ""
    @State private var credits = "5"
    @State private var semester = "Güz"
    @State private var year = "2025"
    @State private var instructor = ""
    @State private var mid = "40"
    @State private var fin = "60"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yeni ders").font(.system(size: 18, weight: .semibold))
            SoftField(placeholder: "Kod (örn. BLM301)", text: $code)
            SoftField(placeholder: "Ders adı", text: $name)
            HStack {
                SoftField(placeholder: "Kredi", text: $credits)
                SoftField(placeholder: "Yıl", text: $year)
            }
            Picker("Dönem", selection: $semester) {
                Text("Güz").tag("Güz")
                Text("Bahar").tag("Bahar")
                Text("Yaz").tag("Yaz")
            }
            SoftField(placeholder: "Hoca", text: $instructor)
            HStack {
                SoftField(placeholder: "Vize %", text: $mid)
                SoftField(placeholder: "Final %", text: $fin)
            }
            HStack {
                Spacer()
                GhostButton(title: "Vazgeç") { dismiss() }
                PrimaryButton(title: "Kaydet") {
                    Task {
                        await store.addCourse(
                            code: code, name: name,
                            credits: Double(credits) ?? 5,
                            semester: semester,
                            year: Int(year) ?? Calendar.current.component(.year, from: Date()),
                            instructor: instructor,
                            mid: Double(mid) ?? 40,
                            fin: Double(fin) ?? 60
                        )
                        dismiss()
                    }
                }
            }
        }
        .padding(22)
        .frame(width: 420)
    }
}

struct CourseDetailSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let course: Course
    @State private var kind = "vize"
    @State private var aname = "Vize"
    @State private var score = ""
    @State private var weight = "40"
    @State private var date = Date()
    @State private var hasDate = true

    var assessments: [Assessment] { store.assessments.filter { $0.courseId == course.id } }
    var result: CourseGradeResult {
        KKUGrading.result(course: course, assessments: assessments, gno: store.gno ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading) {
                    Text(course.name).font(.system(size: 20, weight: .semibold))
                    Text("Vize %\(Int(course.midtermWeight)) · Final %\(Int(course.finalWeight))")
                        .font(.system(size: 12)).foregroundStyle(DS.muted)
                }
                Spacer()
                if let letter = result.letter {
                    Text(letter.rawValue).font(.system(size: 28, weight: .bold, design: .rounded))
                }
            }

            Text(KKUGrading.neededFinalText(result: result, gno: store.gno ?? 0))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.blue)

            ForEach(assessments) { item in
                HStack {
                    Text(item.name).font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text(item.score.map { String(format: "%.0f", $0) } ?? "—")
                    Text("%\(Int(item.weight))").font(.system(size: 11)).foregroundStyle(DS.muted)
                }
            }

            HStack {
                Picker("Tür", selection: $kind) {
                    Text("Vize").tag("vize")
                    Text("Final").tag("final")
                    Text("Bütünleme").tag("butunleme")
                    Text("Quiz").tag("quiz")
                    Text("Ödev").tag("odev")
                }
                SoftField(placeholder: "Ad", text: $aname)
                SoftField(placeholder: "Not", text: $score)
                SoftField(placeholder: "Ağırlık", text: $weight)
            }
            HStack {
                Toggle("Tarih", isOn: $hasDate).controlSize(.mini)
                if hasDate { FormDateField(title: "", date: $date) }
                PrimaryButton(title: "Not ekle") {
                    Task {
                        await store.addAssessment(
                            courseId: course.id,
                            kind: kind,
                            name: aname,
                            score: Double(score.replacingOccurrences(of: ",", with: ".")),
                            weight: Double(weight) ?? 0,
                            date: hasDate ? date : nil
                        )
                        score = ""
                    }
                }
            }

            HStack {
                Spacer()
                GhostButton(title: "Kapat") { dismiss() }
            }
        }
        .padding(22)
        .frame(width: 560)
        .onChange(of: kind) { _, new in
            aname = ["vize": "Vize", "final": "Final", "butunleme": "Bütünleme", "quiz": "Quiz", "odev": "Ödev"][new] ?? new
            weight = new == "vize" ? String(Int(course.midtermWeight)) : (new == "final" || new == "butunleme" ? String(Int(course.finalWeight)) : "10")
        }
    }
}

struct ScheduleView: View {
    @Environment(AppStore.self) private var store
    @State private var courseId: UUID?
    @State private var day = 1
    @State private var start = "09:00"
    @State private var end = "11:00"
    @State private var location = ""

    private let hours = stride(from: 8, through: 18, by: 1).map { $0 }

    var body: some View {
        VStack(spacing: 14) {
            AsistanCard {
                HStack {
                    Picker("Ders", selection: $courseId) {
                        Text("Ders seç").tag(UUID?.none)
                        ForEach(store.courses) { course in
                            Text(course.name).tag(Optional(course.id))
                        }
                    }
                    Picker("Gün", selection: $day) {
                        ForEach(1...5, id: \.self) { d in
                            Text(["", "Pzt", "Sal", "Çar", "Per", "Cum"][d]).tag(d)
                        }
                    }
                    SoftField(placeholder: "09:00", text: $start)
                    SoftField(placeholder: "11:00", text: $end)
                    SoftField(placeholder: "Derslik", text: $location)
                    PrimaryButton(title: "Ekle") {
                        guard let courseId else { return }
                        Task {
                            await store.addMeeting(courseId: courseId, day: day, start: normalize(start), end: normalize(end), location: location)
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)

            AsistanCard {
                VStack(spacing: 0) {
                    HStack {
                        Text("").frame(width: 54)
                        ForEach(["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma"], id: \.self) { d in
                            Text(d).font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 8)
                    ForEach(hours, id: \.self) { hour in
                        HStack(alignment: .top) {
                            Text(String(format: "%02d:00", hour))
                                .font(.system(size: 11))
                                .foregroundStyle(DS.muted)
                                .frame(width: 54, alignment: .leading)
                            ForEach(1...5, id: \.self) { day in
                                ZStack(alignment: .topLeading) {
                                    DS.line.frame(height: 1).offset(y: 0)
                                    ForEach(meetings(day: day, hour: hour)) { meeting in
                                        let course = store.courses.first { $0.id == meeting.courseId }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(course?.name ?? "Ders")
                                                .font(.system(size: 11, weight: .semibold))
                                                .lineLimit(2)
                                            Text(meeting.location ?? "")
                                                .font(.system(size: 10))
                                                .foregroundStyle(DS.muted)
                                        }
                                        .padding(6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(DS.blueSoft)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 52, alignment: .top)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }

    private func meetings(day: Int, hour: Int) -> [CourseMeeting] {
        store.meetings.filter { meeting in
            meeting.dayOfWeek == day && Int(meeting.startTime.prefix(2)) == hour
        }
    }

    private func normalize(_ value: String) -> String {
        let t = value.trimmingCharacters(in: .whitespaces)
        if t.count == 5 { return t + ":00" }
        return t
    }
}
