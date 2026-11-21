import Foundation

final class UserRepositoryImpl: UserRepository {
    private let network: NetworkManager
    private let accessToken: () throws -> String

    init(networkManager: NetworkManager, accessToken: @escaping () throws -> String) {
        self.network = networkManager
        self.accessToken = accessToken
    }

    private func headers() throws -> [String: String] {
        try Mapping.bearerHeaders(accessToken)
    }

    func updateProfile(_ update: UserProfileUpdate) async throws -> UserEntity {
        let response = try await network.request(
            UserEndpoint.updateProfile(update, headers: headers()), as: APIResponseDTO<UserResponseDTO>.self)
        return try UserMapper.map(response.value())
    }
    func profile(publicID: String) async throws -> UserEntity {
        let response = try await network.request(
            UserEndpoint.profile(publicID: publicID), as: APIResponseDTO<UserResponseDTO>.self)
        return try UserMapper.map(response.value())
    }

    func me() async throws -> UserEntity {
        let response = try await network.request(
            UserEndpoint.me(headers: headers()), as: APIResponseDTO<UserResponseDTO>.self)
        return try UserMapper.map(response.value())
    }
}
