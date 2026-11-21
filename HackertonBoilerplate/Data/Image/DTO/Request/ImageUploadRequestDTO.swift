import Foundation

// multipart의 file 필드이며 JSON으로 인코딩하지 않는다.
nonisolated struct ImageUploadRequestDTO: Equatable, Sendable {
    let file: Data
    let fileName: String
    let mimeType: String
    init(input: ImageUploadInput) {
        file = input.data
        fileName = input.fileName
        mimeType = input.mimeType
    }
}
