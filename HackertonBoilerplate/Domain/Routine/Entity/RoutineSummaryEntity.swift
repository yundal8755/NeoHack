import Foundation

nonisolated struct RoutineSummaryEntity: Equatable, Sendable {
    let id: String
    let title: String
    let content: String?
    let owner: RoutineOwnerEntity?
    let thumbnailURL: URL?
    let cardCount: Int64?
    let likeCount: Int64?
    let participantCount: Int64?
    let createdAt: Date?
    var likedByMe: Bool? = nil
    var inProgressCount: Int64? = nil
    var completedCount: Int64? = nil
    var commentCount: Int64? = nil
    var participation: RoutineInteractions.Participation? = nil
}
