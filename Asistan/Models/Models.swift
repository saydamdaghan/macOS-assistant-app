import Foundation

enum AppMode: String, Codable, CaseIterable {
    case work
    case student

    var title: String { self == .work ? "İş Modu" : "Öğrenci Modu" }
    var opening: String { self == .work ? "İş Modu açılıyor…" : "Öğrenci Modu açılıyor…" }
    var icon: String { self == .work ? "briefcase.fill" : "graduationcap.fill" }
}

enum AppPhase: Equatable {
    case launching
    case setup
    case locked
    case modeSelect
    case loading
    case ready
}

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var displayName: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Job: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var title: String
    var client: String?
    var description: String?
    var status: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, client, description, status
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var statusLabel: String {
        switch status {
        case "tamamlandi": return "Tamamlandı"
        case "iptal": return "İptal"
        default: return "Aktif"
        }
    }
}

struct Project: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var jobId: UUID?
    var title: String
    var description: String?
    var status: String
    var completion: Double
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, status, completion
        case userId = "user_id"
        case jobId = "job_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var statusLabel: String {
        switch status {
        case "tamamlandi": return "Tamamlandı"
        case "beklemede": return "Beklemede"
        default: return "Devam ediyor"
        }
    }
}

struct TaskItem: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var projectId: UUID
    var title: String
    var notes: String?
    var status: String
    var priority: String
    var dueDate: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, notes, status, priority
        case userId = "user_id"
        case projectId = "project_id"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isDone: Bool { status == "bitti" }

    var priorityLabel: String {
        switch priority {
        case "yuksek": return "Yüksek"
        case "dusuk": return "Düşük"
        default: return "Orta"
        }
    }
}

struct Payment: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var jobId: UUID
    var title: String?
    var amount: Double
    var dueDate: String?
    var paidAt: Date?
    var status: String
    var notes: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, amount, status, notes
        case userId = "user_id"
        case jobId = "job_id"
        case dueDate = "due_date"
        case paidAt = "paid_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var resolvedStatus: String {
        if status == "odendi" { return "odendi" }
        if DateTools.isOverdue(dueDate) { return "gecikti" }
        return status
    }

    var statusLabel: String {
        switch resolvedStatus {
        case "odendi": return "Ödendi"
        case "gecikti": return "Gecikti"
        default: return "Bekliyor"
        }
    }
}

struct Goal: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var mode: String
    var title: String
    var detail: String?
    var progress: Double
    var target: Double
    var deadline: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, mode, title, detail, progress, target, deadline
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var ratio: Double {
        guard target > 0 else { return 0 }
        return min(progress / target, 1)
    }
}

struct Note: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var mode: String
    var title: String
    var content: String
    var category: String
    var relatedId: UUID?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, mode, title, content, category
        case userId = "user_id"
        case relatedId = "related_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var categoryLabel: String {
        switch category {
        case "ders": return "Ders"
        case "hoca": return "Hoca"
        default: return "Genel"
        }
    }
}

struct CalendarEvent: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var mode: String
    var title: String
    var detail: String?
    var eventDate: String
    var eventTime: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, mode, title, detail
        case userId = "user_id"
        case eventDate = "event_date"
        case eventTime = "event_time"
        case createdAt = "created_at"
    }
}

struct Reminder: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var title: String
    var fireAt: Date
    var relatedType: String?
    var relatedId: UUID?
    var isSent: Bool
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title
        case userId = "user_id"
        case fireAt = "fire_at"
        case relatedType = "related_type"
        case relatedId = "related_id"
        case isSent = "is_sent"
        case createdAt = "created_at"
    }
}

struct Course: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var code: String?
    var name: String
    var credits: Double
    var semester: String
    var year: Int
    var instructor: String?
    var midtermWeight: Double
    var finalWeight: Double
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, code, name, credits, semester, year, instructor
        case userId = "user_id"
        case midtermWeight = "midterm_weight"
        case finalWeight = "final_weight"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var termKey: String { "\(year)-\(semester)" }
}

struct CourseMeeting: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var courseId: UUID
    var dayOfWeek: Int
    var startTime: String
    var endTime: String
    var location: String?

    enum CodingKeys: String, CodingKey {
        case id, location
        case userId = "user_id"
        case courseId = "course_id"
        case dayOfWeek = "day_of_week"
        case startTime = "start_time"
        case endTime = "end_time"
    }

    var dayLabel: String {
        ["", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"][safe: dayOfWeek] ?? "—"
    }
}

struct Assessment: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var courseId: UUID
    var kind: String
    var name: String
    var score: Double?
    var maxScore: Double
    var weight: Double
    var examDate: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, kind, name, score, weight
        case userId = "user_id"
        case courseId = "course_id"
        case maxScore = "max_score"
        case examDate = "exam_date"
        case createdAt = "created_at"
    }

    var kindLabel: String {
        switch kind {
        case "vize": return "Vize"
        case "final": return "Final"
        case "butunleme": return "Bütünleme"
        case "quiz": return "Quiz"
        case "odev": return "Ödev"
        case "proje": return "Proje"
        default: return kind
        }
    }

    var percent: Double? {
        guard let score, maxScore > 0 else { return nil }
        return (score / maxScore) * 100
    }
}

struct Assignment: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var courseId: UUID?
    var title: String
    var detail: String?
    var dueDate: String?
    var status: String
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, detail, status
        case userId = "user_id"
        case courseId = "course_id"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var statusLabel: String {
        switch status {
        case "yapiliyor": return "Yapılıyor"
        case "teslim": return "Teslim"
        case "gecikti": return "Gecikti"
        default: return "Bekliyor"
        }
    }
}

struct Lecturer: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var name: String
    var email: String?
    var office: String?
    var notes: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, email, office, notes
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Scholarship: Codable, Identifiable, Hashable {
    var id: UUID
    var userId: UUID
    var name: String
    var organization: String?
    var amount: Double?
    var deadline: String?
    var status: String
    var notes: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, organization, amount, deadline, status, notes
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var statusLabel: String {
        switch status {
        case "inceleme": return "İnceleme"
        case "kabul": return "Kabul"
        case "red": return "Red"
        default: return "Başvuru"
        }
    }
}

struct CalendarMark: Identifiable, Hashable {
    let id: String
    let date: String
    let title: String
    let kind: String
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
