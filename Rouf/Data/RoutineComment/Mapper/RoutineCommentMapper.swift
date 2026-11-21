nonisolated enum RoutineCommentMapper {
    static func map(_ dto: RoutineCommentResponseDTO) throws -> RoutineCommentEntity {
        try RoutineCommentEntity(
            id: Mapping.identity(dto.commentId, "commentId"), authorNickname: dto.authorNickname,
            profileImageURL: Mapping.url(dto.profileImageUrl, "profileImageUrl"),
            content: Mapping.required(dto.content, "content"), createdAt: Mapping.date(dto.createdAt, "createdAt"),
            isMine: dto.isMine)
    }
}
