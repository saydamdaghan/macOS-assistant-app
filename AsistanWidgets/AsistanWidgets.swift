import SwiftUI
import WidgetKit

struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), payload: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: Date(), payload: load() ?? .sample))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: Date(), payload: load() ?? .empty)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
    }

    private func load() -> WidgetPayload? {
        guard let data = WidgetBridge.defaults()?.data(forKey: WidgetBridge.snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetPayload.self, from: data)
    }
}

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload
}

extension WidgetPayload {
    static let sample = WidgetPayload(
        name: "Kullanıcı",
        tasks: [
            WidgetTaskSnapshot(id: "1", title: "Teklif gönder", project: "Web", due: nil, done: false),
            WidgetTaskSnapshot(id: "2", title: "Fatura kes", project: "Muhasebe", due: nil, done: false)
        ],
        goals: [
            WidgetGoalSnapshot(id: "1", title: "Aylık gelir", progress: 0.62, mode: "work")
        ],
        updatedAt: Date()
    )

    static let empty = WidgetPayload(name: "Kullanıcı", tasks: [], goals: [], updatedAt: Date())
}

struct TasksWidgetView: View {
    let entry: SnapshotEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Görevler")
                .font(.system(size: 13, weight: .semibold))
            if entry.payload.tasks.isEmpty {
                Text("Açık görev yok.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            ForEach(entry.payload.tasks.prefix(4)) { task in
                HStack(spacing: 8) {
                    Circle().strokeBorder(.secondary, lineWidth: 1.2).frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(task.title).font(.system(size: 12, weight: .medium)).lineLimit(1)
                        Text(task.project).font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(4)
    }
}

struct GoalsWidgetView: View {
    let entry: SnapshotEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hedefler")
                .font(.system(size: 13, weight: .semibold))
            if entry.payload.goals.isEmpty {
                Text("Hedef yok.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            ForEach(entry.payload.goals.prefix(3)) { goal in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(goal.title).font(.system(size: 12, weight: .medium)).lineLimit(1)
                        Spacer()
                        Text("\(Int(goal.progress * 100))%").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    ProgressView(value: goal.progress)
                }
            }
            Spacer()
        }
        .padding(4)
    }
}

struct TasksWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AsistanTasksWidget", provider: SnapshotProvider()) { entry in
            TasksWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Görevler")
        .description("Açık iş görevlerini masaüstünde göster.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GoalsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AsistanGoalsWidget", provider: SnapshotProvider()) { entry in
            GoalsWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Hedefler")
        .description("Hedef listeni masaüstünde göster.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct AsistanWidgetBundle: WidgetBundle {
    var body: some Widget {
        TasksWidget()
        GoalsWidget()
    }
}
