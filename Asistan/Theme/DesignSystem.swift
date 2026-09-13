import SwiftUI

enum DS {
    static let bg = Color(red: 0.957, green: 0.965, blue: 0.973)
    static let card = Color.white
    static let sidebar = Color.white
    static let text = Color(red: 0.102, green: 0.110, blue: 0.122)
    static let muted = Color(red: 0.557, green: 0.576, blue: 0.604)
    static let faint = Color(red: 0.690, green: 0.706, blue: 0.729)
    static let line = Color(red: 0.925, green: 0.933, blue: 0.941)
    static let chip = Color(red: 0.965, green: 0.969, blue: 0.976)

    static let blue = Color(red: 0.231, green: 0.510, blue: 0.965)
    static let blueSoft = Color(red: 0.890, green: 0.929, blue: 0.996)
    static let green = Color(red: 0.180, green: 0.737, blue: 0.451)
    static let greenSoft = Color(red: 0.875, green: 0.973, blue: 0.922)
    static let purple = Color(red: 0.545, green: 0.361, blue: 0.965)
    static let purpleSoft = Color(red: 0.933, green: 0.910, blue: 0.996)
    static let orange = Color(red: 0.961, green: 0.620, blue: 0.043)
    static let orangeSoft = Color(red: 1.000, green: 0.949, blue: 0.863)
    static let teal = Color(red: 0.078, green: 0.722, blue: 0.651)
    static let tealSoft = Color(red: 0.800, green: 0.949, blue: 0.937)
    static let red = Color(red: 0.937, green: 0.267, blue: 0.267)
    static let redSoft = Color(red: 0.996, green: 0.890, blue: 0.890)
    static let ink = Color(red: 0.145, green: 0.165, blue: 0.208)

    static let radius: CGFloat = 18
    static let radiusSm: CGFloat = 12
    static let sidebarWidth: CGFloat = 76
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DS.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: DS.radius, style: .continuous)
                    .stroke(DS.line.opacity(0.7), lineWidth: 1)
            )
    }
}

extension View {
    func asistanCard() -> some View {
        modifier(CardModifier())
    }
}

struct AsistanCard<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .asistanCard()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let delta: String?
    let deltaPositive: Bool
    let icon: String
    let tint: Color
    let soft: Color

    var body: some View {
        AsistanCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DS.muted)
                    Text(value)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.text)
                    if let delta {
                        Text(delta)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(deltaPositive ? DS.green : DS.red)
                    }
                }
                Spacer(minLength: 8)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(soft)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
            }
        }
    }
}

struct SectionTitle: View {
    let title: String
    var action: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.text)
            Spacer()
            if let action {
                Text(action)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.muted)
            }
        }
    }
}

struct StatusBadge: View {
    let text: String
    let tint: Color
    let soft: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(soft)
            .clipShape(Capsule())
    }
}

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var fill: Color = DS.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct GhostButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(DS.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DS.chip)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SoftField: View {
    let placeholder: String
    @Binding var text: String
    var secure: Bool = false

    var body: some View {
        Group {
            if secure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .textFieldStyle(.plain)
        .font(.system(size: 14))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DS.chip)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct IconTile: View {
    let icon: String
    let tint: Color
    let soft: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(soft)
                .frame(width: 56, height: 56)
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

struct RingProgress: View {
    var progress: Double
    var size: CGFloat = 120
    var line: CGFloat = 12
    var tint: Color = DS.teal

    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.line, lineWidth: line)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.text)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DS.faint)
            TextField("Ara…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 220)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DS.line, lineWidth: 1)
        )
    }
}

enum Greeting {
    static func hello(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let prefix: String
        switch hour {
        case 5..<12: prefix = "Günaydın"
        case 12..<18: prefix = "İyi günler"
        default: prefix = "İyi akşamlar"
        }
        return "\(prefix) \(name)"
    }

    static var todayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy, EEEE"
        return f.string(from: Date())
    }
}

enum Formatters {
    static let money: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.numberStyle = .currency
        f.currencyCode = "TRY"
        f.maximumFractionDigits = 0
        return f
    }()

    static func tryAmount(_ value: Double) -> String {
        money.string(from: NSNumber(value: value)) ?? "₺0"
    }

    static func day(_ iso: String?) -> String {
        guard let iso, let date = DateTools.date(iso) else { return "—" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    static func longDay(_ iso: String?) -> String {
        guard let iso, let date = DateTools.date(iso) else { return "—" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }
}

enum DateTools {
    static let isoDay: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func date(_ iso: String) -> Date? {
        isoDay.date(from: String(iso.prefix(10)))
    }

    static func iso(_ date: Date) -> String {
        isoDay.string(from: date)
    }

    static func isOverdue(_ iso: String?) -> Bool {
        guard let iso, let date = date(iso) else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }
}
