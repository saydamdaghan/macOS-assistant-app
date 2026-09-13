import Foundation
import LocalAuthentication

enum BiometricError: LocalizedError {
    case failed
    case unavailable

    var errorDescription: String? {
        switch self {
        case .failed: return "Touch ID doğrulanamadı."
        case .unavailable: return "Bu Mac’te Touch ID kullanılamıyor."
        }
    }
}

enum BiometricService {
    static var canUseTouchID: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    @MainActor
    static func unlock(reason: String = "Asistan’a girmek için Touch ID kullanın") async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Vazgeç"
        var error: NSError?
        let policy: LAPolicy
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            policy = .deviceOwnerAuthenticationWithBiometrics
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            policy = .deviceOwnerAuthentication
        } else {
            throw BiometricError.unavailable
        }

        do {
            let ok = try await context.evaluatePolicy(policy, localizedReason: reason)
            if !ok { throw BiometricError.failed }
        } catch {
            throw BiometricError.failed
        }
    }
}
