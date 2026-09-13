import Foundation

/// Kırıkkale Üniversitesi Ön Lisans / Lisans Eğitim-Öğretim Yönetmeliği
/// harf notu aralıkları ve katsayıları.
enum KKULetter: String, CaseIterable, Identifiable {
    case AA, BA, BB, CB, CC, DC, DD, FF

    var id: String { rawValue }

    var coefficient: Double {
        switch self {
        case .AA: return 4.00
        case .BA: return 3.50
        case .BB: return 3.00
        case .CB: return 2.50
        case .CC: return 2.00
        case .DC: return 1.50
        case .DD: return 1.00
        case .FF: return 0.00
        }
    }

    var rangeLabel: String {
        switch self {
        case .AA: return "88–100"
        case .BA: return "81–87"
        case .BB: return "74–80"
        case .CB: return "67–73"
        case .CC: return "60–66"
        case .DC: return "55–59"
        case .DD: return "50–54"
        case .FF: return "0–49"
        }
    }

    var minScore: Double {
        switch self {
        case .AA: return 88
        case .BA: return 81
        case .BB: return 74
        case .CB: return 67
        case .CC: return 60
        case .DC: return 55
        case .DD: return 50
        case .FF: return 0
        }
    }

    var isPass: Bool { self == .AA || self == .BA || self == .BB || self == .CB || self == .CC }
    var isConditional: Bool { self == .DC || self == .DD }
    var isFail: Bool { self == .FF }

    var resultLabel: String {
        if isPass { return "Geçer" }
        if isConditional { return "Koşullu geçer" }
        return "Kalır"
    }

    static func fromScore(_ score: Double) -> KKULetter {
        switch score {
        case 88...: return .AA
        case 81..<88: return .BA
        case 74..<81: return .BB
        case 67..<74: return .CB
        case 60..<67: return .CC
        case 55..<60: return .DC
        case 50..<55: return .DD
        default: return .FF
        }
    }
}

struct CourseGradeResult: Hashable {
    let course: Course
    let currentScore: Double?
    let letter: KKULetter?
    let weightedPoints: Double
    let knownWeight: Double
    let neededFor: [KKULetter: Double?]
}

enum KKUGrading {
    static func currentScore(assessments: [Assessment], course: Course) -> (score: Double?, knownWeight: Double) {
        let graded = assessments.filter { $0.percent != nil }
        let knownWeight = graded.reduce(0) { $0 + $1.weight }
        guard knownWeight > 0 else { return (nil, 0) }
        let acc = graded.reduce(0.0) { $0 + (($1.percent ?? 0) * $1.weight / 100) }
        return (acc / (knownWeight / 100), knownWeight)
    }

    static func result(course: Course, assessments: [Assessment], gno: Double) -> CourseGradeResult {
        let (score, known) = currentScore(assessments: assessments, course: course)
        let letter = score.map { KKULetter.fromScore($0) }
        let points = (letter?.coefficient ?? 0) * course.credits

        var needed: [KKULetter: Double?] = [:]
        let remaining = max(0, 100 - known)
        for target in KKULetter.allCases where target != .FF {
            if remaining <= 0 {
                needed[target] = score.map { $0 >= target.minScore ? 0 : nil } ?? nil
            } else if let score {
                let requiredTotal = target.minScore
                let have = score * (known / 100)
                let needOnRemaining = (requiredTotal - have) / (remaining / 100)
                needed[target] = needOnRemaining
            } else {
                needed[target] = target.minScore
            }
        }

        return CourseGradeResult(
            course: course,
            currentScore: score,
            letter: letter,
            weightedPoints: points,
            knownWeight: known,
            neededFor: needed
        )
    }

    static func termAverage(courses: [Course], assessments: [Assessment]) -> Double? {
        var credits = 0.0
        var points = 0.0
        for course in courses {
            let related = assessments.filter { $0.courseId == course.id }
            let result = result(course: course, assessments: related, gno: 0)
            guard result.letter != nil else { continue }
            credits += course.credits
            points += (result.letter?.coefficient ?? 0) * course.credits
        }
        guard credits > 0 else { return nil }
        return points / credits
    }

    static func neededFinalText(result: CourseGradeResult, gno: Double) -> String {
        let passTarget = KKULetter.CC
        let conditional = gno >= 2.0 ? KKULetter.DD : KKULetter.CC
        let target = passTarget
        guard let raw = result.neededFor[target] else {
            return "Hesaplanamadı"
        }
        if let raw {
            if raw <= 0 { return "\(target.rawValue) zaten görünüyor" }
            if raw > 100 { return "\(target.rawValue) için final yetersiz kalır (\(Int(raw.rounded())) gerekir)" }
            return "CC için finalden en az \(Int(ceil(raw)))"
        }
        return "\(target.rawValue) bu notlarla mümkün değil"
            + (conditional != target ? ". Koşullu geçiş GNO ≥ 2.00 ister." : "")
    }
}
