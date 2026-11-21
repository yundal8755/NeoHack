import Foundation

final class UserRepositoryImpl: UserRepository {
    private let network: NetworkManager
    private let userID: String?
    private let deviceToken: () throws -> String

    init(networkManager: NetworkManager, deviceToken: @escaping () throws -> String, userID: String? = nil) {
        self.network = networkManager
        self.deviceToken = deviceToken
        self.userID = userID
    }

    private func headers() throws -> [String: String] {
        try Mapping.deviceHeaders(deviceToken, userID: userID)
    }

    func list() async throws -> [UserEntity] {
        let response = try await network.request(
            UserEndpoint.list(headers: headers()), as: APIResponseDTO<[UserResponseDTO]>.self)
        return try response.value().map(UserMapper.map)
    }
    func create(nickname: String, bio: String? = nil) async throws -> UserEntity {
        let response = try await network.request(
            UserEndpoint.create(nickname: nickname, bio: bio, headers: headers()), as: APIResponseDTO<UserResponseDTO>.self)
        return try UserMapper.map(response.value())
    }
    func me() async throws -> UserEntity {
        let response = try await network.request(
            UserEndpoint.me(headers: headers()), as: APIResponseDTO<UserResponseDTO>.self)
        return try UserMapper.map(response.value())
    }
}
