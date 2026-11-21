import Foundation

nonisolated struct UploadedImageEntity: Equatable, Sendable {
    let id: String
    let contentType: String?
    let byteSize: Int?
    let width: Int?
    let height: Int?
    let imageURL: URL?
}
