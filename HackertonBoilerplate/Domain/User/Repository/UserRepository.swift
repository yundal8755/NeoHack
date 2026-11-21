import Foundation

nonisolated protocol UserRepository {
    func list() async throws -> [UserEntity]
    func create(nickname: String) async throws -> UserEntity
    func me() async throws -> UserEntity
}
