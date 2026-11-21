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
    let createdAt: String?
    var myParticipationStatus: String? = nil
}
