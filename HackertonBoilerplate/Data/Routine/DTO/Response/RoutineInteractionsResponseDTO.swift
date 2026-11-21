nonisolated struct RoutineInteractionsResponseDTO: Decodable, Equatable, Sendable {
    let likeCount: Int?
    let likedByMe: Bool?
    let inProgressCount: Int?
    let completedCount: Int?
    let myParticipationStatus: String?
}
