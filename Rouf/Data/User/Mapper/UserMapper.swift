nonisolated enum UserMapper {
    static func map(_ dto: UserResponseDTO) throws -> UserEntity {
        try UserEntity(
            id: Mapping.identity(dto.publicId, "publicId"), nickname: Mapping.required(dto.nickname, "nickname"),
            profileImageID: dto.profileImagePublicId, bio: dto.bio,
            profileImageURL: dto.profileImagePublicId.flatMap(ImageEndpoint.imageURL))
    }
}
