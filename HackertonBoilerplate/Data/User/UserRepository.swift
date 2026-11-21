import Foundation

protocol UserRepositoryProtocol {
    var hasAccessToken: Bool { get }
    func fetchProfile() async throws(NetworkError) -> UserProfile
    func signOut()
}

final class UserRepository: UserRepositoryProtocol {
    private let networkManager: NetworkManager
    private let tokenStore: TokenStoring

    init(networkManager: NetworkManager, tokenStore: TokenStoring) {
        self.networkManager = networkManager
        self.tokenStore = tokenStore
    }

    var hasAccessToken: Bool {
        tokenStore.accessToken?.isEmpty == false
    }

    func fetchProfile() async throws(NetworkError) -> UserProfile {
        let response = try await networkManager.request(
            UserEndpoint.profile,
            as: ServerResponse<UserProfileResponseDTO>.self
        )

        guard response.success, let data = response.data else {
            throw .unknown(errorCode: response.error?.code ?? "USER_PROFILE_FAILED")
        }

        return UserMapper.map(data)
    }

    func signOut() {
        tokenStore.clear()
    }
}
