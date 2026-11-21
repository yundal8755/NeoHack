import Foundation

nonisolated struct ImageUploadResponseDTO: Decodable, Equatable, Sendable {
    let imageId: String?
    let contentType: String?
    let byteSize: Int?
    let width: Int?
    let height: Int?
    let imageUrl: String?
}
