import Foundation

final class UserRepositoryImpl: UserRepository {
    private let network: NetworkManager
    private let deviceToken: () throws -> String

    init(networkManager: NetworkManager, deviceToken: @escaping () throws -> String) {
        self.network = networkManager
        self.deviceToken = deviceToken
    }

    private func headers() throws -> [String: String] {
        try Mapping.deviceHeaders(deviceToken)
    }

    func list() async throws -> [UserEntity] {
        let response = try await network.request(
            UserEndpoint.list(headers: headers()), as: APIResponseDTO<[UserResponseDTO]>.self)
        return try response.value().map(UserMapper.map)
    }
    func create(nickname: String) async throws -> UserEntity {
        let response = try await network.request(
            UserEndpoint.create(nickname: nickname, headers: headers()), as: APIResponseDTO<UserResponseDTO>.self)
        return try UserMapper.map(response.value())
    }
    func me() async throws -> UserEntity {
        let response = try await network.request(
            UserEndpoint.me(headers: headers()), as: APIResponseDTO<UserResponseDTO>.self)
        return try UserMapper.map(response.value())
    }
}
