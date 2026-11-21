import Foundation

nonisolated protocol UserRepository {
    func list() async throws -> [UserEntity]
    func create(nickname: String, bio: String?) async throws -> UserEntity
    func updateProfile(_ update: UserProfileUpdate) async throws -> UserEntity
    func me() async throws -> UserEntity
}

extension UserRepository {
    func create(nickname: String) async throws -> UserEntity {
        try await create(nickname: nickname, bio: nil)
    }
}
