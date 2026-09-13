import SwiftUI
import Charts

struct FinanceView: View {
    @Environment(AppStore.self) private var store

    private var paid: Double { store.payments.filter { $0.status == "odendi" }.reduce(0) { $0 + $1.amount } }
    private var waiting: Double { store.payments.filter { $0.resolvedStatus != "odendi" }.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    StatCard(title: "Toplam gelen", value: Formatters.tryAmount(paid), delta: nil, deltaPositive: true, icon: "arrow.down.circle.fill", tint: DS.green, soft: DS.greenSoft)
                    StatCard(title: "Bekleyen", value: Formatters.tryAmount(waiting), delta: nil, deltaPositive: false, icon: "clock.fill", tint: DS.orange, soft: DS.orangeSoft)
                    StatCard(title: "Bu ay", value: Formatters.tryAmount(store.monthIncome), delta: nil, deltaPositive: true, icon: "calendar", tint: DS.teal, soft: DS.tealSoft)
                }

                AsistanCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(title: "Gelirler")
                        Chart(store.payments.filter { $0.status == "odendi" }, id: \.id) { item in
                            BarMark(
                                x: .value("İş", store.jobs.first { $0.id == item.jobId }?.title ?? "İş"),
                                y: .value("Tutar", item.amount)
                            )
                            .foregroundStyle(DS.teal)
                            .cornerRadius(6)
                        }
                        .frame(height: 180)
                    }
                }

                AsistanCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "Ödeme listesi")
                        ForEach(store.payments) { payment in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(payment.title ?? store.jobs.first { $0.id == payment.jobId }?.title ?? "Ödeme")
                                        .font(.system(size: 13, weight: .medium))
                                    Text(Formatters.longDay(payment.dueDate))
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.muted)
                                }
                                Spacer()
                                Text(Formatters.tryAmount(payment.amount))
                                    .font(.system(size: 13, weight: .semibold))
                                StatusBadge(
                                    text: payment.statusLabel,
                                    tint: payment.resolvedStatus == "odendi" ? DS.green : (payment.resolvedStatus == "gecikti" ? DS.red : DS.orange),
                                    soft: payment.resolvedStatus == "odendi" ? DS.greenSoft : (payment.resolvedStatus == "gecikti" ? DS.redSoft : DS.orangeSoft)
                                )
                                if payment.status != "odendi" {
                                    PrimaryButton(title: "Onayla") {
                                        Task { await store.confirmPayment(payment) }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        if store.payments.isEmpty {
                            EmptyHint(text: "İşler bölümünden ödeme planı ekle.")
                        }
                    }
                }
            }
            .padding(28)
        }
    }
}
