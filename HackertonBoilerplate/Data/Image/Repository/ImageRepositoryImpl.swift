import Foundation

final class ImageRepositoryImpl: ImageRepository {
    private let network: NetworkManager
    private let deviceToken: () throws -> String

    init(networkManager: NetworkManager, deviceToken: @escaping () throws -> String) {
        self.network = networkManager
        self.deviceToken = deviceToken
    }

    private func headers() throws -> [String: String] {
        try Mapping.deviceHeaders(deviceToken)
    }

    func upload(input: ImageUploadInput) async throws -> UploadedImageEntity {
        let dto = ImageUploadRequestDTO(input: input)
        guard !dto.file.isEmpty, !dto.fileName.isEmpty,
            !dto.fileName.contains(where: { $0 == "\"" || $0.asciiValue.map { $0 < 32 || $0 == 127 } == true }),
            dto.mimeType.range(of: "^image/[A-Za-z0-9!#$&^_.+-]+$", options: .regularExpression) != nil
        else {
            throw DataContractError.invalidValue("file")
        }
        let response = try await network.upload(
            ImageEndpoint.upload(headers: headers()), file: dto.file, fileName: dto.fileName, mimeType: dto.mimeType,
            as: APIResponseDTO<ImageUploadResponseDTO>.self)
        return try ImageMapper.map(response.value())
    }
    func data(id: String) async throws -> Data {
        try await network.requestData(ImageEndpoint.data(id: id))
    }
}
