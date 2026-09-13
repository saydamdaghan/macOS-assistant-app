import SwiftUI
import AppKit

struct SetupView: View {
    @Environment(AppStore.self) private var store
    @State private var url = ""
    @State private var anon = ""
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var create = true

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text("A")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(DS.text)
                Text("Merhaba,\nOdak zamanı.")
                    .font(.system(size: 34, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DS.text)
                Text("Supabase bilgilerini bir kez gir. Sonraki girişler yalnızca Touch ID ile.")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            AsistanCard(padding: 22) {
                VStack(spacing: 12) {
                    SoftField(placeholder: "https://xxxx.supabase.co", text: $url)
                    SoftField(placeholder: "anon / publishable key (eyJ...)", text: $anon)
                    SoftField(placeholder: "Ad", text: $name)
                    SoftField(placeholder: "E-posta", text: $email)
                    SoftField(placeholder: "Şifre", text: $password, secure: true)
                    Picker("", selection: $create) {
                        Text("Yeni hesap").tag(true)
                        Text("Var olan hesap").tag(false)
                    }
                    .pickerStyle(.segmented)
                    Button {
                        Task {
                            await store.completeSetup(
                                url: url, anon: anon, email: email,
                                password: password, name: name, create: create
                            )
                        }
                    } label: {
                        Text(store.busy ? "Kaydediliyor…" : "Devam et")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .foregroundStyle(.white)
                            .background(DS.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(store.busy || url.isEmpty || anon.isEmpty || email.isEmpty || password.isEmpty)
                }
                .frame(width: 380)
            }
        }
    }
}

struct TouchIDView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.muted)
                    .padding(8)
                    .background(DS.chip)
                    .clipShape(Circle())
                    .onTapGesture { NSApplication.shared.terminate(nil) }
                Spacer()
            }
            .frame(width: 360)

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(DS.chip)
                    .frame(width: 88, height: 88)
                Image(systemName: "touchid")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(DS.text)
            }

            VStack(spacing: 8) {
                Text("Touch ID")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DS.text)
                Text("Uygulamayı açmak için parmağını kullan.")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.muted)
            }

            Button("Vazgeç") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.muted)
        }
        .task { await store.unlock() }
    }
}

struct ModeSelectView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 8) {
                Text("Hangi modda devam edelim?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(DS.text)
                Text("İş ve öğrenci alanların birbirinden ayrı durur.")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.muted)
            }

            HStack(spacing: 18) {
                ModeCard(
                    title: "İş Modu",
                    subtitle: "İşler, projeler, ödemeler, finans, hedefler",
                    icon: "briefcase.fill",
                    tint: DS.blue,
                    soft: DS.blueSoft
                ) {
                    Task { await store.choose(.work) }
                }
                ModeCard(
                    title: "Öğrenci Modu",
                    subtitle: "Dersler, sınavlar, ödevler, notlar, burslar",
                    icon: "graduationcap.fill",
                    tint: DS.purple,
                    soft: DS.purpleSoft
                ) {
                    Task { await store.choose(.student) }
                }
            }

            VStack(spacing: 10) {
                Image(systemName: "touchid")
                    .font(.system(size: 18))
                    .foregroundStyle(DS.faint)
                Text("Oturum Touch ID ile açık.")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.faint)
            }
        }
    }
}

struct ModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let soft: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                IconTile(icon: icon, tint: tint, soft: soft)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.text)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
            .frame(width: 260, alignment: .leading)
            .asistanCard()
        }
        .buttonStyle(.plain)
    }
}

struct ModeLoadingView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 18) {
            IconTile(
                icon: store.mode.icon,
                tint: store.mode == .work ? DS.ink : DS.purple,
                soft: store.mode == .work ? DS.chip : DS.purpleSoft
            )
            Text(store.mode.opening)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DS.text)
        }
    }
}
