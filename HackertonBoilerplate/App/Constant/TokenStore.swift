import Foundation
import Security

protocol TokenStoring {
    var accessToken: String? { get set }
    func clear()
}

final class KeychainTokenStore: TokenStoring {
    private let service: String
    private let account: String

    init(service: String = Bundle.main.bundleIdentifier ?? "HackertonBoilerplate", account: String = "accessToken") {
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
        clear()

        var item = query
        item[kSecValueData as String] = Data(token.utf8)
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
