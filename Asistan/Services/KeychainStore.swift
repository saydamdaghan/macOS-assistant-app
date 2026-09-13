import Foundation
import Security

enum KeychainStore {
    static let service = "com.daghan.asistan.config"
    static let urlKey = "supabase_url"
    static let anonKey = "supabase_anon_key"

    static var hasConfig: Bool {
        url != nil && anon != nil
    }

    static var url: String? { read(urlKey) }
    static var anon: String? { read(anonKey) }

    static func saveConfig(url: String, anon: String) {
        write(url, for: urlKey)
        write(anon, for: anonKey)
    }

    static func clearConfig() {
        delete(urlKey)
        delete(anonKey)
    }

    static func write(_ value: String, for key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        SecItemAdd(add as CFDictionary, nil)
    }

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
