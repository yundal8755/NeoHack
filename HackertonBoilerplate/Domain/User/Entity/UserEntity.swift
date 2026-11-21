import Foundation

nonisolated struct UserEntity: Equatable, Sendable {
    let id: String
    let nickname: String
    let profileImageID: String?
}
