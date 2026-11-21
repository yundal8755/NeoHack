import Foundation

nonisolated struct RoutineDetailResponseDTO: Decodable, Equatable, Sendable {
    let routineId: String?
    let title: String?
    let content: String?
    let owner: RoutineOwnerResponseDTO?
    let cards: [RoutineCardResponseDTO]?
    let likeCount: Int64?
    let commentCount: Int64?
    let createdAt: String?
    let updatedAt: String?
}
