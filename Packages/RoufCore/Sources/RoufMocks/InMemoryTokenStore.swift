import Foundation
import RoufCore

/// Keychain 대신 메모리에 토큰을 보관한다. 테스트와 목 모드에서 사용한다.
public final class InMemoryTokenStore: TokenStoring {
    public var accessToken: String?

    public init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }

    public func clear() {
        accessToken = nil
    }
}
