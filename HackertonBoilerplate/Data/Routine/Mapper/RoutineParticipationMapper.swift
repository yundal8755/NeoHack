nonisolated enum RoutineParticipationMapper {
    static func request(_ draft: RoutineParticipationDraft) throws -> RoutineParticipationDraftDTO {
        guard (draft.title?.count ?? 0) <= 30, (draft.content?.count ?? 0) <= 500,
            (draft.cards?.count ?? 0) <= 10
        else { throw DataContractError.invalidValue("draft") }
        let cards = try draft.cards?.map { card -> RoutineParticipationDraftDTO.Card? in
            guard let card else { return nil }
            if let imageID = card.imageID { _ = try Mapping.pathID(imageID) }
            guard (card.title?.count ?? 0) <= 30, (card.content?.count ?? 0) <= 100 else {
                throw DataContractError.invalidValue("draft.card")
            }
            if let time = card.time, !Mapping.isCardTime(time) {
                throw DataContractError.invalidValue("time")
            }
            return .init(imageId: card.imageID, title: card.title, content: card.content, time: card.time)
        }
        return .init(title: draft.title, content: draft.content, cards: cards)
    }

    static func draft(_ dto: RoutineParticipationDraftDTO) -> RoutineParticipationDraft {
        .init(
            title: dto.title, content: dto.content,
            cards: dto.cards?.map { card in
                card.map { .init(imageID: $0.imageId, title: $0.title, content: $0.content, time: $0.time) }
            })
    }

    static func result(_ dto: RoutineParticipationResultDTO) throws -> RoutineParticipationResult {
        try .init(
            routineID: Mapping.identity(dto.routineId, "routineId"),
            participant: dto.participant.map(RoutineMapper.owner), work: dto.work.map(draft),
            completedAt: Mapping.date(dto.completedAt, "completedAt"))
    }

    static func results(_ dto: RoutineParticipationResultsDTO) throws -> RoutineParticipationResults {
        let summaries = try dto.results?.map { summary in
            try RoutineParticipationResults.Summary(
                participant: summary.participant.map(RoutineMapper.owner), title: summary.title,
                content: summary.content,
                thumbnailURL: Mapping.url(summary.thumbnailUrl, "thumbnailUrl"),
                completedAt: Mapping.date(summary.completedAt, "completedAt"))
        }
        return .init(results: summaries, totalCount: dto.totalCount)
    }
}
