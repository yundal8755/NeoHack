nonisolated struct RoutineParticipationDraftDTO: Codable, Equatable, Sendable {
    struct Card: Codable, Equatable, Sendable {
        let imageId: String?
        let title: String?
        let content: String?
        let time: String?
    }

    let title: String?
    let content: String?
    let cards: [Card?]?
}
