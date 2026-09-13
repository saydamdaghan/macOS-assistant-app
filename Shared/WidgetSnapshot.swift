import Foundation

enum WidgetBridge {
    static let suite = "group.com.daghan.asistan"
    static let snapshotKey = "widget_snapshot"

    static func defaults() -> UserDefaults? {
        UserDefaults(suiteName: suite)
    }
}

struct WidgetTaskSnapshot: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var project: String
    var due: String?
    var done: Bool
}

struct WidgetGoalSnapshot: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var progress: Double
    var mode: String
}

struct WidgetPayload: Codable, Hashable {
    var name: String
    var tasks: [WidgetTaskSnapshot]
    var goals: [WidgetGoalSnapshot]
    var updatedAt: Date
}
