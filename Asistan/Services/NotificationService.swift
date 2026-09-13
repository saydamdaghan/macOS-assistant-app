import Foundation
import UserNotifications

enum NotificationService {
    static func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func rebuild(
        payments: [Payment],
        tasks: [TaskItem],
        assignments: [Assignment],
        assessments: [Assessment],
        scholarships: [Scholarship],
        events: [CalendarEvent],
        jobs: [Job],
        courses: [Course]
    ) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let jobNames = Dictionary(uniqueKeysWithValues: jobs.map { ($0.id, $0.title) })
        let courseNames = Dictionary(uniqueKeysWithValues: courses.map { ($0.id, $0.name) })

        for payment in payments where payment.status != "odendi" {
            if let date = fireDate(iso: payment.dueDate, hour: 10) {
                let title = payment.title ?? jobNames[payment.jobId] ?? "Ödeme"
                await schedule(
                    id: "pay-\(payment.id.uuidString)",
                    title: "Ödeme hatırlatması",
                    body: "\(title) — \(Formatters.tryAmount(payment.amount))",
                    date: date
                )
            }
        }

        for task in tasks where !task.isDone {
            if let date = fireDate(iso: task.dueDate, hour: 9) {
                await schedule(
                    id: "task-\(task.id.uuidString)",
                    title: "Görev hatırlatması",
                    body: task.title,
                    date: date
                )
            }
        }

        for item in assignments where item.status != "teslim" {
            if let date = fireDate(iso: item.dueDate, hour: 9) {
                let course = item.courseId.flatMap { courseNames[$0] } ?? "Ödev"
                await schedule(
                    id: "hw-\(item.id.uuidString)",
                    title: "Ödev teslimi",
                    body: "\(item.title) · \(course)",
                    date: date
                )
            }
        }

        for exam in assessments where exam.kind == "vize" || exam.kind == "final" || exam.kind == "butunleme" {
            if let date = fireDate(iso: exam.examDate, hour: 8) {
                await schedule(
                    id: "exam-\(exam.id.uuidString)",
                    title: "Sınav hatırlatması",
                    body: "\(exam.name) · \(courseNames[exam.courseId] ?? "Ders")",
                    date: date
                )
            }
        }

        for item in scholarships where item.status == "basvuru" || item.status == "inceleme" {
            if let date = fireDate(iso: item.deadline, hour: 10) {
                await schedule(
                    id: "sch-\(item.id.uuidString)",
                    title: "Burs son tarihi",
                    body: item.name,
                    date: date
                )
            }
        }

        for event in events {
            if let date = fireDate(iso: event.eventDate, hour: hour(from: event.eventTime) ?? 9) {
                await schedule(
                    id: "evt-\(event.id.uuidString)",
                    title: "Takvim",
                    body: event.title,
                    date: date
                )
            }
        }
    }

    private static func hour(from time: String?) -> Int? {
        guard let time else { return nil }
        let part = time.split(separator: ":").first
        return part.flatMap { Int($0) }
    }

    private static func fireDate(iso: String?, hour: Int) -> Date? {
        guard let iso, let day = DateTools.date(iso) else { return nil }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        comps.hour = hour
        comps.minute = 0
        guard let date = Calendar.current.date(from: comps), date > Date() else { return nil }
        return date
    }

    private static func schedule(id: String, title: String, body: String, date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
