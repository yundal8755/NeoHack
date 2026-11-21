import Foundation

extension Notification.Name {
    static let authSessionExpired = Notification.Name("auth.sessionExpired")
}

protocol AccessTokenRefreshing: AnyObject {
    func refreshAccessToken() async throws(NetworkError) -> String?
}

final class AuthInterceptor {
    private var tokenStore: TokenStoring
    private let tokenRefresher: AccessTokenRefreshing?

    init(
        tokenStore: TokenStoring,
        tokenRefresher: AccessTokenRefreshing? = nil
    ) {
        self.tokenStore = tokenStore
        self.tokenRefresher = tokenRefresher
    }

    func adapt(_ request: URLRequest, for target: any TargetType) -> URLRequest {
        guard target.requiresAuthentication,
              let accessToken = tokenStore.accessToken,
              accessToken.isEmpty == false,
              request.value(forHTTPHeaderField: "Authorization") == nil else {
            return request
        }

        var request = request
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        AppLogger.debug("Attached authorization header")
        return request
    }

    func refreshAccessToken() async throws(NetworkError) -> String? {
        guard let refreshedToken = try await tokenRefresher?.refreshAccessToken(), refreshedToken.isEmpty == false else {
            return nil
        }

        tokenStore.accessToken = refreshedToken
        AppLogger.info("Access token refreshed")
        return refreshedToken
    }

    func expireSession() {
        tokenStore.clear()
        NotificationCenter.default.post(name: .authSessionExpired, object: nil)
        AppLogger.info("Session expired; access token cleared")
    }
}
