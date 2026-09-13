import SwiftUI

struct ProjectsView: View {
    @Environment(AppStore.self) private var store
    @State private var selected: Project?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                ForEach(store.projects) { project in
                    Button { selected = project } label: {
                        AsistanCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(project.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(DS.text)
                                        .lineLimit(1)
                                    Spacer()
                                    StatusBadge(
                                        text: project.statusLabel,
                                        tint: project.status == "tamamlandi" ? DS.green : DS.blue,
                                        soft: project.status == "tamamlandi" ? DS.greenSoft : DS.blueSoft
                                    )
                                }
                                Text(project.description ?? "İşten oluşan proje")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.muted)
                                    .lineLimit(2)
                                ProgressView(value: min(project.completion / 100, 1))
                                    .tint(DS.teal)
                                HStack {
                                    Text("\(Int(project.completion))% tamamlandı")
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.muted)
                                    Spacer()
                                    Text("\(store.tasks(for: project).filter(\.isDone).count)/\(store.tasks(for: project).count) görev")
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.muted)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(28)
        }
        .sheet(item: $selected) { project in
            ProjectDetailSheet(project: project)
        }
    }
}

struct ProjectDetailSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let project: Project
    @State private var title = ""
    @State private var priority = "orta"
    @State private var due = Date()
    @State private var hasDue = false

    var items: [TaskItem] { store.tasks(for: project) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(project.title).font(.system(size: 20, weight: .semibold))
                Spacer()
                RingProgress(progress: min(project.completion / 100, 1), size: 64, line: 7, tint: DS.teal)
            }

            SectionTitle(title: "Görevler")
            ForEach(items) { task in
                HStack(spacing: 10) {
                    Button {
                        Task { await store.toggleTask(task) }
                    } label: {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isDone ? DS.green : DS.faint)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.system(size: 13, weight: .medium))
                            .strikethrough(task.isDone)
                        HStack(spacing: 8) {
                            Text(task.priorityLabel).font(.system(size: 11)).foregroundStyle(DS.muted)
                            if let due = task.dueDate {
                                Text(Formatters.day(due)).font(.system(size: 11)).foregroundStyle(DateTools.isOverdue(due) && !task.isDone ? DS.red : DS.muted)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        Task { await store.deleteTask(task) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.faint)
                    }
                    .buttonStyle(.plain)
                }
            }
            if items.isEmpty {
                EmptyHint(text: "Görev ekle. Bittikçe tamamlanma yüzdesi dolar.")
            }

            HStack {
                SoftField(placeholder: "Yeni görev", text: $title)
                Picker("Öncelik", selection: $priority) {
                    Text("Düşük").tag("dusuk")
                    Text("Orta").tag("orta")
                    Text("Yüksek").tag("yuksek")
                }
                .frame(width: 110)
                Toggle("Tarih", isOn: $hasDue).toggleStyle(.switch).controlSize(.mini)
                if hasDue { FormDateField(title: "", date: $due) }
                PrimaryButton(title: "Ekle") {
                    guard !title.isEmpty else { return }
                    Task {
                        await store.addTask(projectId: project.id, title: title, priority: priority, due: hasDue ? due : nil)
                        title = ""
                    }
                }
            }

            HStack {
                Spacer()
                GhostButton(title: "Kapat") { dismiss() }
            }
        }
        .padding(24)
        .frame(width: 620)
    }
}
