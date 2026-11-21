import Foundation

final class RoutineRepositoryImpl: RoutineRepository {
    private let network: NetworkManager
    private let deviceToken: () throws -> String

    init(networkManager: NetworkManager, deviceToken: @escaping () throws -> String) {
        self.network = networkManager
        self.deviceToken = deviceToken
    }

    private func headers() throws -> [String: String] {
        try Mapping.deviceHeaders(deviceToken)
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
    func delete(id: String) async throws {
        let response = try await network.request(
            RoutineEndpoint.delete(id: id, headers: headers()), as: APIDeleteResponseDTO.self)
        try response.checkSuccess()
    }
}
