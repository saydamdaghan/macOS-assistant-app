import SwiftUI

struct JobsView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false
    @State private var selected: Job?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                PrimaryButton(title: "İş ekle", icon: "plus") { showAdd = true }
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)

            ScrollView {
                VStack(spacing: 12) {
                    if store.jobs.isEmpty {
                        AsistanCard { EmptyHint(text: "İlk işini ekle. İş açılınca proje otomatik oluşur.") }
                    }
                    ForEach(store.jobs) { job in
                        JobRow(job: job, project: store.project(for: job), payments: store.payments(for: job))
                            .onTapGesture { selected = job }
                    }
                }
                .padding(28)
            }
        }
        .sheet(isPresented: $showAdd) { AddJobSheet() }
        .sheet(item: $selected) { job in
            JobDetailSheet(job: job)
        }
    }
}

struct JobRow: View {
    let job: Job
    let project: Project?
    let payments: [Payment]

    var body: some View {
        AsistanCard {
            HStack(alignment: .center, spacing: 16) {
                IconTile(icon: "briefcase.fill", tint: DS.blue, soft: DS.blueSoft)
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.system(size: 15, weight: .semibold))
                    Text(job.client?.isEmpty == false ? job.client! : "Müşteri belirtilmedi")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    StatusBadge(
                        text: job.statusLabel,
                        tint: job.status == "tamamlandi" ? DS.green : DS.blue,
                        soft: job.status == "tamamlandi" ? DS.greenSoft : DS.blueSoft
                    )
                    Text("Tamamlanma \(Int(project?.completion ?? 0))%")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.muted)
                }
                .frame(width: 140, alignment: .trailing)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Formatters.tryAmount(payments.reduce(0) { $0 + $1.amount }))
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(payments.filter { $0.status == "odendi" }.count)/\(payments.count) ödeme")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.muted)
                }
                .frame(width: 130, alignment: .trailing)
            }
        }
        .contentShape(Rectangle())
    }
}

struct AddJobSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var client = ""
    @State private var detail = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Yeni iş").font(.system(size: 18, weight: .semibold))
            SoftField(placeholder: "İş adı", text: $title)
            SoftField(placeholder: "Müşteri / firma", text: $client)
            SoftField(placeholder: "Açıklama", text: $detail)
            HStack {
                Spacer()
                GhostButton(title: "Vazgeç") { dismiss() }
                PrimaryButton(title: "Kaydet") {
                    Task {
                        await store.addJob(title: title, clientName: client, detail: detail)
                        dismiss()
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

struct JobDetailSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let job: Job
    @State private var payTitle = "Ara ödeme"
    @State private var payAmount = ""
    @State private var payDate = Date()

    var project: Project? { store.project(for: job) }
    var pays: [Payment] { store.payments(for: job) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title).font(.system(size: 20, weight: .semibold))
                    Text(job.client ?? "—").font(.system(size: 13)).foregroundStyle(DS.muted)
                }
                Spacer()
                StatusBadge(text: "Proje %\(Int(project?.completion ?? 0))", tint: DS.teal, soft: DS.tealSoft)
            }

            if let detail = job.description, !detail.isEmpty {
                Text(detail).font(.system(size: 13)).foregroundStyle(DS.muted)
            }

            SectionTitle(title: "Ödeme planı")
            ForEach(pays) { payment in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(payment.title ?? "Ödeme").font(.system(size: 13, weight: .medium))
                        Text(Formatters.longDay(payment.dueDate)).font(.system(size: 11)).foregroundStyle(DS.muted)
                    }
                    Spacer()
                    Text(Formatters.tryAmount(payment.amount)).font(.system(size: 13, weight: .semibold))
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
            if pays.isEmpty {
                Text("Henüz ödeme planı yok.").font(.system(size: 12)).foregroundStyle(DS.muted)
            }

            HStack {
                SoftField(placeholder: "Ödeme adı", text: $payTitle)
                TextField("Tutar", text: $payAmount)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(DS.chip)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .frame(width: 110)
                FormDateField(title: "Tarih", date: $payDate)
                PrimaryButton(title: "Planla") {
                    Task {
                        await store.addPayment(jobId: job.id, title: payTitle, amount: Double(payAmount.replacingOccurrences(of: ",", with: ".")) ?? 0, due: payDate)
                        payAmount = ""
                    }
                }
            }

            HStack {
                GhostButton(title: "Tamamlandı işaretle") {
                    Task { await store.setJobStatus(job, status: "tamamlandi") }
                }
                GhostButton(title: "İşi sil") {
                    Task { await store.deleteJob(job); dismiss() }
                }
                Spacer()
                GhostButton(title: "Kapat") { dismiss() }
            }
        }
        .padding(24)
        .frame(width: 640)
    }
}
