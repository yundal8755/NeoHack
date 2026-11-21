nonisolated enum ImageMapper {
    static func map(_ dto: ImageUploadResponseDTO) throws -> UploadedImageEntity {
        try UploadedImageEntity(
            id: Mapping.identity(dto.imageId, "imageId"), contentType: dto.contentType, byteSize: dto.byteSize,
            width: dto.width, height: dto.height, imageURL: Mapping.url(dto.imageUrl, "imageUrl"))
    }
}
