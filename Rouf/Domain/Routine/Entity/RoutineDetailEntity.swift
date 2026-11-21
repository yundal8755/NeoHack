import Foundation

nonisolated struct RoutineDetailEntity: Equatable, Sendable {
    let id: String
    let title: String
    let content: String?
    let owner: RoutineOwnerEntity?
    let cards: [RoutineCardEntity]?
    let likeCount: Int64?
    let commentCount: Int64?
    let createdAt: Date?
    let updatedAt: Date?
}
