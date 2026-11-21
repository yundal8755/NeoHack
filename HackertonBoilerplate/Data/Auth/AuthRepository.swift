import Foundation

protocol AuthRepositoryProtocol {
    var hasAccessToken: Bool { get }
    func login(loginId: String, password: String) async throws(NetworkError) -> LoginResult
    func signOut()
}

final class AuthRepository: AuthRepositoryProtocol {
    private let networkManager: NetworkManager
    private var tokenStore: TokenStoring

    init(networkManager: NetworkManager, tokenStore: TokenStoring) {
        self.networkManager = networkManager
        self.tokenStore = tokenStore
    }

    var hasAccessToken: Bool {
        tokenStore.accessToken?.isEmpty == false
    }

    func login(loginId: String, password: String) async throws(NetworkError) -> LoginResult {
        AppLogger.info("Login request started")
        let request = AuthLoginRequestDTO(loginId: loginId, password: password)
        let response = try await networkManager.request(
            AuthEndpoint.login(request),
            as: AuthLoginEnvelopeDTO.self
        )

        guard response.success, let data = response.data, data.accessToken.isEmpty == false else {
            if response.message.isEmpty == false {
                throw .apiError(code: String(response.code), message: response.message)
            }
            throw .unknown(errorCode: "AUTH_LOGIN_FAILED")
        }

        let result = AuthMapper.map(data)
        tokenStore.accessToken = result.accessToken
        AppLogger.info("Login request succeeded")
        return result
    }

    func logout() async throws(NetworkError) {
        AppLogger.info("Logout request started")
        let response = try await networkManager.request(
            AuthEndpoint.logout,
            as: ServerResponse<String>.self
        )

        guard response.success else {
            if let error = response.error {
                throw .apiError(code: error.code, message: error.message)
            }

            throw .unknown(errorCode: "AUTH_LOGOUT_FAILED")
        }

        tokenStore.clear()
        AppLogger.info("Logout request succeeded")
    }

    func signOut() {
        tokenStore.clear()
    }
}
