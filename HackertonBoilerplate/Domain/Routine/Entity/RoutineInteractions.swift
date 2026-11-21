nonisolated struct RoutineInteractions: Equatable, Sendable {
    enum Participation: String, Sendable {
        case notJoined = "NOT_PARTICIPATING"
        case joined = "IN_PROGRESS"
        case completed = "COMPLETED"
    }
    enum Change: Sendable { case like, unlike, join, leave, complete }

    let likeCount: Int
    let likedByMe: Bool
    let inProgressCount: Int
    let completedCount: Int
    let participation: Participation
}
