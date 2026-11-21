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
}
