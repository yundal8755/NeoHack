import Foundation

final class RoutineCommentRepositoryImpl: RoutineCommentRepository {
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

    func list(routineID: String) async throws -> [RoutineCommentEntity] {
        let response = try await network.request(
            RoutineCommentEndpoint.list(routineID: routineID, headers: headers()),
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
