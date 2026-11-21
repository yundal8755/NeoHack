import Foundation

nonisolated struct ParticipationResultResponseDTO: Decodable, Sendable {
    let routineId: String?
    let participant: RoutineOwnerResponseDTO?
    let work: Work?
    let completedAt: String?

    struct Work: Decodable, Sendable {
        let title: String?
        let content: String?
        let cards: [RoutineCardResponseDTO?]?
    }
}
