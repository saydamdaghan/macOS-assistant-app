import SwiftUI
import Charts

struct WorkDashboardView: View {
    @Environment(AppStore.self) private var store

    private var activeProjects: Int { store.projects.filter { $0.status == "devam" }.count }
    private var doneProjects: Int { store.projects.filter { $0.status == "tamamlandi" }.count }
    private var weekDone: Int {
        store.tasks.filter { $0.isDone }.count
    }
    private var weekTotal: Int { max(store.tasks.count, 1) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    StatCard(title: "Aktif Proje", value: "\(activeProjects)", delta: nil, deltaPositive: true, icon: "square.grid.2x2.fill", tint: DS.blue, soft: DS.blueSoft)
                    StatCard(title: "Tamamlanan", value: "\(doneProjects)", delta: nil, deltaPositive: true, icon: "checkmark.circle.fill", tint: DS.green, soft: DS.greenSoft)
                    StatCard(title: "Bu Ay Gelir", value: Formatters.tryAmount(store.monthIncome), delta: nil, deltaPositive: true, icon: "turkishlirasign.circle.fill", tint: DS.teal, soft: DS.tealSoft)
                    StatCard(title: "Bekleyen Ödeme", value: Formatters.tryAmount(store.pendingIncome), delta: nil, deltaPositive: false, icon: "clock.fill", tint: DS.orange, soft: DS.orangeSoft)
                }

                HStack(alignment: .top, spacing: 14) {
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitle(title: "Bu Hafta")
                            HStack {
                                Spacer()
                                RingProgress(progress: Double(weekDone) / Double(weekTotal), size: 132, tint: DS.teal)
                                Spacer()
                            }
                            Text("\(weekDone)/\(store.tasks.count) görev bitti")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.muted)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle(title: "Görev Dağılımı")
                            taskBar("Bekliyor", count: store.tasks.filter { $0.status == "bekliyor" }.count, color: DS.orange)
                            taskBar("Yapılıyor", count: store.tasks.filter { $0.status == "yapiliyor" }.count, color: DS.blue)
                            taskBar("Bitti", count: store.tasks.filter { $0.isDone }.count, color: DS.green)
                        }
                    }
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle(title: "Aylık Gelir / Gider")
                            Chart(monthlyPayments(), id: \.label) { row in
                                BarMark(x: .value("Ay", row.label), y: .value("Tutar", row.value))
                                    .foregroundStyle(DS.teal)
                                    .cornerRadius(6)
                            }
                            .frame(height: 150)
                            .chartXAxis {
                                AxisMarks { _ in
                                    AxisValueLabel().font(.system(size: 10)).foregroundStyle(DS.muted)
                                }
                            }
                            .chartYAxis(.hidden)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 14) {
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Yaklaşanlar")
                            let upcoming = store.marks(for: .work).sorted { $0.date < $1.date }.prefix(5)
                            if upcoming.isEmpty { EmptyHint(text: "Yaklaşan ödeme veya görev yok.") }
                            ForEach(Array(upcoming)) { item in
                                HStack {
                                    Circle().fill(DS.orange).frame(width: 6, height: 6)
                                    Text(item.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(DS.text)
                                    Spacer()
                                    Text(Formatters.day(item.date))
                                        .font(.system(size: 12))
                                        .foregroundStyle(DS.muted)
                                }
                            }
                        }
                    }
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Son Aktiviteler")
                            let latest = store.jobs.prefix(5)
                            if latest.isEmpty { EmptyHint(text: "Henüz iş yok.") }
                            ForEach(Array(latest)) { job in
                                HStack {
                                    Text(job.title)
                                        .font(.system(size: 13, weight: .medium))
                                    Spacer()
                                    StatusBadge(text: job.statusLabel, tint: DS.blue, soft: DS.blueSoft)
                                }
                            }
                        }
                    }
                    AsistanCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Büyük Hedefler")
                            if store.workGoals.isEmpty { EmptyHint(text: "Hedef ekle.") }
                            ForEach(store.workGoals.prefix(4)) { goal in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(goal.title).font(.system(size: 13, weight: .medium))
                                        Spacer()
                                        Text("\(Int(goal.ratio * 100))%").font(.system(size: 12)).foregroundStyle(DS.muted)
                                    }
                                    ProgressView(value: goal.ratio)
                                        .tint(DS.purple)
                                }
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
    }

    private func taskBar(_ title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.system(size: 12)).foregroundStyle(DS.muted)
                Spacer()
                Text("\(count)").font(.system(size: 12, weight: .semibold))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.chip)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * CGFloat(min(Double(count) / Double(max(store.tasks.count, 1)), 1)))
                }
            }
            .frame(height: 8)
        }
    }

    private func monthlyPayments() -> [(label: String, value: Double)] {
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "MMM"
        return (0..<6).reversed().compactMap { offset -> (String, Double)? in
            guard let date = cal.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let sum = store.payments
                .filter { $0.status == "odendi" && $0.paidAt.map { cal.isDate($0, equalTo: date, toGranularity: .month) } == true }
                .reduce(0) { $0 + $1.amount }
            return (f.string(from: date), sum)
        }
    }
}
