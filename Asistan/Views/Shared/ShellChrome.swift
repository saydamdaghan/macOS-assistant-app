import SwiftUI

struct SidebarRail<Tab: Hashable>: View {
    let tabs: [(Tab, String, String)]
    @Binding var selection: Tab
    let name: String
    var onAvatar: () -> Void = {}

    var body: some View {
        VStack(spacing: 18) {
            Text("A")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(DS.text)
                .padding(.top, 18)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { _, item in
                        Button {
                            selection = item.0
                        } label: {
                            Image(systemName: item.1)
                                .font(.system(size: 16, weight: selection == item.0 ? .semibold : .regular))
                                .foregroundStyle(selection == item.0 ? DS.text : DS.faint)
                                .frame(width: 42, height: 42)
                                .background(selection == item.0 ? DS.chip : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .help(item.2)
                    }
                }
            }

            Spacer(minLength: 8)

            Button(action: onAvatar) {
                ZStack {
                    Circle().fill(DS.ink).frame(width: 34, height: 34)
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 18)
            .help(name)
        }
        .frame(width: DS.sidebarWidth)
        .background(DS.sidebar)
        .overlay(alignment: .trailing) {
            DS.line.frame(width: 1)
        }
    }
}

struct TopBar: View {
    let modeTitle: String
    let greeting: String
    let subtitle: String
    @Binding var search: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(modeTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.muted)
                Text(greeting)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DS.text)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.faint)
            }
            Spacer()
            SearchField(text: $search)
            Text(Greeting.todayLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DS.muted)
        }
        .padding(.horizontal, 28)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }
}

struct PageHeader: View {
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DS.text)
            Spacer()
            if let trailing { trailing }
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
    }
}

struct EmptyHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(DS.muted)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
    }
}

struct FormDateField: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        DatePicker(title, selection: $date, displayedComponents: .date)
            .datePickerStyle(.field)
            .font(.system(size: 13))
    }
}
