import Foundation

nonisolated struct RoutineCommentEntity: Equatable, Sendable {
    let id: String
    let authorNickname: String?
    let profileImageURL: URL?
    let content: String
    let createdAt: Date?
    let isMine: Bool?
}
