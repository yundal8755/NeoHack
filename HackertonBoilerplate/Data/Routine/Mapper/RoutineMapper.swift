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
                try $0.map {
                    try RoutineCardEntity(
                        imageID: Mapping.identity($0.imageId, "imageId"), title: $0.title, content: $0.content,
                        time: $0.time)
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
    static func page(_ dto: RoutinePageResponseDTO) throws -> RoutinePageEntity {
        try RoutinePageEntity(
            routines: dto.routines.map { try $0.map(summary) }, size: dto.size, hasNext: dto.hasNext,
            nextCursor: dto.nextCursor)
    }
}
