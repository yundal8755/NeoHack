import Foundation

nonisolated protocol RoutineCommentRepository {
    func list(routineID: String) async throws -> [RoutineCommentEntity]
    func create(routineID: String, content: String) async throws -> RoutineCommentEntity
    func update(routineID: String, commentID: String, content: String) async throws -> RoutineCommentEntity
    func delete(routineID: String, commentID: String) async throws
}
