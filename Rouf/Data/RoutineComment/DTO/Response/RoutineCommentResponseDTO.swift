import Foundation

nonisolated struct RoutineCommentResponseDTO: Decodable, Equatable, Sendable {
    let commentId: String?
    let authorNickname: String?
    let profileImageUrl: String?
    let content: String?
    let createdAt: String?
    let isMine: Bool?
}
