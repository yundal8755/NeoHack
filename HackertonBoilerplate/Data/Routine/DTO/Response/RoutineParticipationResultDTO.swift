nonisolated struct RoutineParticipationResultDTO: Decodable, Sendable {
    let routineId: String?
    let participant: RoutineOwnerResponseDTO?
    let work: RoutineParticipationDraftDTO?
    let completedAt: String?
}

nonisolated struct RoutineParticipationResultsDTO: Decodable, Sendable {
    struct Summary: Decodable, Sendable {
        let participant: RoutineOwnerResponseDTO?
        let title: String?
        let content: String?
        let thumbnailUrl: String?
        let completedAt: String?
    }

    let results: [Summary]?
    let totalCount: Int?
}
