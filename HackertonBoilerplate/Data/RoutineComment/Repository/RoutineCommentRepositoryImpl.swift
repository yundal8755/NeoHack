import Foundation

final class RoutineCommentRepositoryImpl: RoutineCommentRepository {
    private let network: NetworkManager
    private let accessToken: (() throws -> String)?

    init(networkManager: NetworkManager, accessToken: (() throws -> String)? = nil) {
        self.network = networkManager
        self.accessToken = accessToken
    }

    private func headers() throws -> [String: String] {
        guard let accessToken else { throw DataContractError.missingAccessToken }
        return try Mapping.bearerHeaders(accessToken)
    }

    func list(routineID: String) async throws -> [RoutineCommentEntity] {
        let response = try await network.request(
            RoutineCommentEndpoint.list(routineID: routineID, headers: accessToken == nil ? [:] : headers()),
            as: APIResponseDTO<[RoutineCommentResponseDTO]>.self)
        return try response.value().map(RoutineCommentMapper.map)
    }
    func create(routineID: String, content: String) async throws -> RoutineCommentEntity {
        let response = try await network.request(
            RoutineCommentEndpoint.save(routineID: routineID, content: content, headers: headers()),
            as: APIResponseDTO<RoutineCommentResponseDTO>.self)
        return try RoutineCommentMapper.map(response.value())
    }
    func update(routineID: String, commentID: String, content: String) async throws -> RoutineCommentEntity {
        let response = try await network.request(
            RoutineCommentEndpoint.save(
                routineID: routineID, commentID: commentID, content: content, headers: headers()),
            as: APIResponseDTO<RoutineCommentResponseDTO>.self)
        return try RoutineCommentMapper.map(response.value())
    }
    func delete(routineID: String, commentID: String) async throws {
        let response = try await network.request(
            RoutineCommentEndpoint.delete(routineID: routineID, commentID: commentID, headers: headers()),
            as: APIDeleteResponseDTO.self)
        try response.checkSuccess()
    }
}
