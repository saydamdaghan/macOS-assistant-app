import Foundation
import WidgetKit

enum WidgetBridgeWriter {
    static func publish(name: String, tasks: [TaskItem], projects: [Project], goals: [Goal]) {
        let projectNames = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0.title) })
        let openTasks = tasks
            .filter { !$0.isDone }
            .sorted { ($0.dueDate ?? "9999") < ($1.dueDate ?? "9999") }
            .prefix(5)
            .map {
                WidgetTaskSnapshot(
                    id: $0.id.uuidString,
                    title: $0.title,
                    project: projectNames[$0.projectId] ?? "Proje",
                    due: $0.dueDate,
                    done: false
                )
            }

        let goalSnaps = goals.prefix(4).map {
            WidgetGoalSnapshot(
                id: $0.id.uuidString,
                title: $0.title,
                progress: $0.ratio,
                mode: $0.mode
            )
        }

        let payload = WidgetPayload(
            name: name,
            tasks: Array(openTasks),
            goals: goalSnaps,
            updatedAt: Date()
        )

        if let data = try? JSONEncoder().encode(payload) {
            WidgetBridge.defaults()?.set(data, forKey: WidgetBridge.snapshotKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
