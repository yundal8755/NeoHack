import Foundation

nonisolated struct RoutineParticipationDraft: Equatable, Sendable {
    struct Card: Equatable, Sendable {
        var imageID: String?
        var title: String?
        var content: String?
        var time: String?
    }

    var title: String?
    var content: String?
    var cards: [Card?]?
}

nonisolated struct RoutineParticipationResult: Equatable, Sendable {
    let routineID: String
    let participant: RoutineOwnerEntity?
    let work: RoutineParticipationDraft?
    let completedAt: Date?
}

nonisolated struct RoutineParticipationResults: Equatable, Sendable {
    struct Summary: Equatable, Sendable {
        let participant: RoutineOwnerEntity?
        let title: String?
        let content: String?
        let thumbnailURL: URL?
        let completedAt: Date?
    }

    let results: [Summary]?
    let totalCount: Int?
}

nonisolated enum RoutineParticipationError: LocalizedError {
    case completionRequiresInput

    var errorDescription: String? { "참여를 완료하려면 작성한 제목과 스텝이 필요해요." }
}
