import Foundation

nonisolated protocol ImageRepository {
    func uploadGeneral(input: ImageUploadInput) async throws -> UploadedImageEntity
    func uploadStep(input: ImageUploadInput) async throws -> UploadedImageEntity
    func uploadProfile(input: ImageUploadInput) async throws -> UploadedImageEntity
    func data(id: String) async throws -> Data
}

extension ImageRepository {
    // The existing routine composer uses upload(input:) for card images.
    func upload(input: ImageUploadInput) async throws -> UploadedImageEntity {
        try await uploadStep(input: input)
    }
}
