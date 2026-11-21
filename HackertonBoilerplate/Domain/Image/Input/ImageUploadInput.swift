import Foundation

nonisolated struct ImageUploadInput: Equatable, Sendable {
    let data: Data
    let fileName: String
    let mimeType: String
}
