import Foundation
import RoufCore
import Security

final class KeychainTokenStore: TokenStoring {
    private let service: String
    private let account: String

    init(service: String = Bundle.main.bundleIdentifier ?? "Rouf", account: String = "accessToken") {
        self.service = service
        self.account = account
    }

    var accessToken: String? {
        get { read() }
        set {
            if let newValue {
                save(newValue)
            } else {
                clear()
            }
        }
    }

    func clear() {
        SecItemDelete(query as CFDictionary)
    }

    private func save(_ token: String) {
        let value = [kSecValueData as String: Data(token.utf8)]
        let status = SecItemUpdate(query as CFDictionary, value as CFDictionary)
        guard status == errSecItemNotFound else { return }

        var item = query
        item.merge(value) { _, new in new }
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }

    private func read() -> String? {
        var item = query
        item[kSecReturnData as String] = true
        item[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(item as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
