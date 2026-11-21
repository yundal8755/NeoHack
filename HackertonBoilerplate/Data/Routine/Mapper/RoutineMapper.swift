nonisolated enum RoutineMapper {
    static func request(_ input: RoutineSaveInput) -> RoutineSaveRequestDTO {
        RoutineSaveRequestDTO(
            title: input.title, content: input.content,
            cards: input.cards.map {
                RoutineCardRequestDTO(imageId: $0.imageID, title: $0.title, content: $0.content, time: $0.time)
            })
    }
    static func owner(_ dto: RoutineOwnerResponseDTO) throws -> RoutineOwnerEntity {
        try RoutineOwnerEntity(
            id: Mapping.identity(dto.userId, "owner.userId"), nickname: dto.nickname,
            profileImageURL: Mapping.url(dto.profileImageUrl, "profileImageUrl"))
    }
    static func detail(_ dto: RoutineDetailResponseDTO) throws -> RoutineDetailEntity {
        try RoutineDetailEntity(
            id: Mapping.identity(dto.routineId, "routineId"), title: Mapping.required(dto.title, "title"),
            content: dto.content, owner: dto.owner.map(owner),
            cards: dto.cards.map {
                try $0.enumerated().sorted { lhs, rhs in
                    let left = lhs.element.order ?? Int.max
                    let right = rhs.element.order ?? Int.max
                    return left == right ? lhs.offset < rhs.offset : left < right
                }.map { _, card in
                    try RoutineCardEntity(
                        id: card.cardId, order: card.order, imageURL: Mapping.url(card.imageUrl, "imageUrl"),
                        imageID: Mapping.identity(card.imageId, "imageId"),
                        title: Mapping.required(card.title, "card.title"), content: card.content,
                        time: Mapping.required(card.time, "time"))
                }
            }, likeCount: dto.likeCount, commentCount: dto.commentCount,
            createdAt: Mapping.date(dto.createdAt, "createdAt"), updatedAt: Mapping.date(dto.updatedAt, "updatedAt"))
    }
    static func summary(_ dto: RoutineSummaryResponseDTO) throws -> RoutineSummaryEntity {
        try RoutineSummaryEntity(
            id: Mapping.identity(dto.routineId, "routineId"), title: Mapping.required(dto.title, "title"),
            content: dto.content, owner: dto.owner.map(owner),
            thumbnailURL: Mapping.url(dto.thumbnailUrl, "thumbnailUrl"), cardCount: dto.cardCount,
            likeCount: dto.likeCount, participantCount: dto.participantCount,
            createdAt: Mapping.date(dto.createdAt, "createdAt"))
    }
    static func interactions(_ dto: RoutineInteractionsResponseDTO) throws -> RoutineInteractions {
        let status = try Mapping.required(dto.myParticipationStatus, "myParticipationStatus")
        guard let participation = RoutineInteractions.Participation(rawValue: status) else {
            throw DataContractError.invalidValue("myParticipationStatus")
        }
        return try RoutineInteractions(
            likeCount: Mapping.required(dto.likeCount, "likeCount"),
            likedByMe: Mapping.required(dto.likedByMe, "likedByMe"),
            inProgressCount: Mapping.required(dto.inProgressCount, "inProgressCount"),
            completedCount: Mapping.required(dto.completedCount, "completedCount"),
            participation: participation)
    }
    static func page(_ dto: RoutinePageResponseDTO) throws -> RoutinePageEntity {
        try RoutinePageEntity(
            routines: dto.routines.map { try $0.map(summary) }, size: dto.size, hasNext: dto.hasNext,
            nextCursor: dto.nextCursor)
    }
}
