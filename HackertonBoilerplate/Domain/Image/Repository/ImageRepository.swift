import Foundation

nonisolated protocol ImageRepository {
    func upload(input: ImageUploadInput) async throws -> UploadedImageEntity
    func data(id: String) async throws -> Data
}
