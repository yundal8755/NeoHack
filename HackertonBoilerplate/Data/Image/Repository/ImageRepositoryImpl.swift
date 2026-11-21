import Foundation

final class ImageRepositoryImpl: ImageRepository {
    private let network: NetworkManager
    private let accessToken: () throws -> String

    init(networkManager: NetworkManager, accessToken: @escaping () throws -> String) {
        self.network = networkManager
        self.accessToken = accessToken
    }

    private func headers() throws -> [String: String] {
        try Mapping.bearerHeaders(accessToken)
    }

    func upload(input: ImageUploadInput) async throws -> UploadedImageEntity {
        try await upload(ImageEndpoint.upload(headers: headers()), input: input)
    }

    func uploadProfile(input: ImageUploadInput) async throws -> UploadedImageEntity {
        guard input.data.count <= 5_000_000 else { throw ProfileImageUploadError.tooLarge }
        guard ["image/jpeg", "image/png", "image/heic", "image/heif"].contains(input.mimeType.lowercased()) else {
            throw DataContractError.invalidValue("file")
        }
        return try await upload(ImageEndpoint.uploadProfile(headers: headers()), input: input)
    }

    private func upload(_ endpoint: APIEndpoint, input: ImageUploadInput) async throws -> UploadedImageEntity {
        let dto = ImageUploadRequestDTO(input: input)
        guard !dto.file.isEmpty, !dto.fileName.isEmpty,
            !dto.fileName.contains(where: { $0 == "\"" || $0.asciiValue.map { $0 < 32 || $0 == 127 } == true }),
            dto.mimeType.range(of: "^image/[A-Za-z0-9!#$&^_.+-]+$", options: .regularExpression) != nil
        else {
            throw DataContractError.invalidValue("file")
        }
        let response = try await network.upload(
            endpoint, file: dto.file, fileName: dto.fileName, mimeType: dto.mimeType,
            as: APIResponseDTO<ImageUploadResponseDTO>.self)
        return try ImageMapper.map(response.value())
    }
    func data(id: String) async throws -> Data {
        try await network.requestData(ImageEndpoint.data(id: id))
    }
}

private enum ProfileImageUploadError: LocalizedError {
    case tooLarge
    var errorDescription: String? { "프로필 사진은 5MB까지 올릴 수 있어요." }
}
