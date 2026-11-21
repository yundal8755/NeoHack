import Foundation

final class RoutineRepositoryImpl: RoutineRepository {
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

    func list(query: RoutineListQuery) async throws -> RoutinePageEntity {
        let response = try await network.request(
            RoutineEndpoint.list(query: query), as: APIResponseDTO<RoutinePageResponseDTO>.self)
        return try RoutineMapper.page(response.value())
    }
    func detail(id: String) async throws -> RoutineDetailEntity {
        let response = try await network.request(
            RoutineEndpoint.detail(id: id), as: APIResponseDTO<RoutineDetailResponseDTO>.self)
        return try RoutineMapper.detail(response.value())
    }
    func create(input: RoutineSaveInput) async throws -> RoutineDetailEntity {
        let response = try await network.request(
            RoutineEndpoint.save(input: input, headers: headers()), as: APIResponseDTO<RoutineDetailResponseDTO>.self)
        return try RoutineMapper.detail(response.value())
    }
    func update(id: String, input: RoutineSaveInput) async throws -> RoutineDetailEntity {
        let response = try await network.request(
            RoutineEndpoint.save(id: id, input: input, headers: headers()),
            as: APIResponseDTO<RoutineDetailResponseDTO>.self)
        return try RoutineMapper.detail(response.value())
    }
    func interactions(id: String, change: RoutineInteractions.Change?) async throws -> RoutineInteractions {
        let response = try await network.request(
            RoutineEndpoint.interactions(id: id, change: change, headers: headers()),
            as: APIResponseDTO<RoutineInteractionsResponseDTO>.self)
        return try RoutineMapper.interactions(response.value())
    }
    func delete(id: String) async throws {
        let response = try await network.request(
            RoutineEndpoint.delete(id: id, headers: headers()), as: APIDeleteResponseDTO.self)
        try response.checkSuccess()
    }
}
