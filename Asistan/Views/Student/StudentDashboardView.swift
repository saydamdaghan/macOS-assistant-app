import SwiftUI
import Charts

struct StudentDashboardView: View {
    @Environment(AppStore.self) private var store

    private var upcomingHW: [Assignment] {
        store.assignments.filter { $0.status != "teslim" }.prefix(5).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    StatCard(title: "Aktif Ders", value: "\(store.currentTermCourses.count)", delta: nil, deltaPositive: true, icon: "book.fill", tint: DS.blue, soft: DS.blueSoft)
                    StatCard(title: "Yaklaşan", value: "\(store.marks(for: .student).count)", delta: nil, deltaPositive: true, icon: "calendar", tint: DS.orange, soft: DS.orangeSoft)
                    StatCard(title: "Tamamlanan Ödev", value: "\(store.assignments.filter { $0.status == "teslim" }.count)", delta: nil, deltaPositive: true, icon: "checkmark.circle.fill", tint: DS.green, soft: DS.greenSoft)
                    StatCard(
                        title: "Ortalama Not",
                        value: store.gno.map { String(format: "%.2f", $0) } ?? "—",
                        delta: store.gno.map { $0 >= 2 ? "+ GNO" : "GNO < 2.00" },
                        deltaPositive: (store.gno ?? 0) >= 2,
                        icon: "chart.line.uptrend.xyaxis",
                        tint: DS.purple,
                        soft: DS.purpleSoft
                    )
                }

                HStack(alignment: .top, spacing: 14) {
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Not Ortalaması")
                            Chart(gpaSeries(), id: \.label) { row in
                                LineMark(x: .value("Dönem", row.label), y: .value("GNO", row.value))
                                    .foregroundStyle(DS.blue)
                                AreaMark(x: .value("Dönem", row.label), y: .value("GNO", row.value))
                                    .foregroundStyle(DS.blue.opacity(0.12))
                            }
                            .chartYScale(domain: 0...4)
                            .frame(height: 160)
                        }
                    }
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Sınav Takvimi")
                            let exams = store.assessments.filter { $0.examDate != nil }.sorted { ($0.examDate ?? "") < ($1.examDate ?? "") }.prefix(6)
                            if exams.isEmpty { EmptyHint(text: "Sınav tarihi yok.") }
                            ForEach(Array(exams)) { exam in
                                HStack {
                                    Text(exam.name).font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    Text(Formatters.day(exam.examDate)).font(.system(size: 12)).foregroundStyle(DS.muted)
                                }
                            }
                        }
                    }
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Yaklaşan Ödevler")
                            if upcomingHW.isEmpty { EmptyHint(text: "Bekleyen ödev yok.") }
                            ForEach(upcomingHW) { item in
                                HStack {
                                    Text(item.title).font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    Text(Formatters.day(item.dueDate)).font(.system(size: 12)).foregroundStyle(DS.muted)
                                }
                            }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 14) {
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Küçük Hedefler")
                            if store.studentGoals.isEmpty { EmptyHint(text: "Öğrenci hedefi ekle.") }
                            ForEach(store.studentGoals.prefix(4)) { goal in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(goal.title).font(.system(size: 13, weight: .medium))
                                        Spacer()
                                        Text("\(Int(goal.ratio * 100))%").font(.system(size: 12)).foregroundStyle(DS.muted)
                                    }
                                    ProgressView(value: goal.ratio).tint(DS.green)
                                }
                            }
                        }
                    }
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Burslar")
                            ForEach(store.scholarships.prefix(4)) { item in
                                HStack {
                                    Text(item.name).font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    StatusBadge(
                                        text: item.statusLabel,
                                        tint: item.status == "kabul" ? DS.green : (item.status == "red" ? DS.red : DS.orange),
                                        soft: item.status == "kabul" ? DS.greenSoft : (item.status == "red" ? DS.redSoft : DS.orangeSoft)
                                    )
                                }
                            }
                            if store.scholarships.isEmpty { EmptyHint(text: "Burs başvurusu yok.") }
                        }
                    }
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(title: "KKÜ Portal")
                            Text("Öğrenci Bilgi Sistemi’ne git.")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.muted)
                            PrimaryButton(title: "obs.kku.edu.tr", icon: "arrow.up.right") {
                                store.openKKUPortal()
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
    }

    private func gpaSeries() -> [(label: String, value: Double)] {
        let groups = Dictionary(grouping: store.courses, by: \.termKey)
        return groups.keys.sorted().compactMap { key in
            let list = groups[key] ?? []
            guard let avg = KKUGrading.termAverage(courses: list, assessments: store.assessments) else { return nil }
            return (key, avg)
        }
    }
}
