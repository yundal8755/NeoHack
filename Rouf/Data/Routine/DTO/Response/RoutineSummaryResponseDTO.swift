import Foundation

nonisolated struct RoutineSummaryResponseDTO: Decodable, Equatable, Sendable {
    let routineId: String?
    let title: String?
    let content: String?
    let owner: RoutineOwnerResponseDTO?
    let thumbnailUrl: String?
    let cardCount: Int64?
    let likeCount: Int64?
    let participantCount: Int64?
    let likedByMe: Bool?
    let inProgressCount: Int64?
    let completedCount: Int64?
    let commentCount: Int64?
    let myParticipationStatus: String?
    let createdAt: String?
}
