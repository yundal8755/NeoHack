import Foundation

nonisolated struct UserCreateRequestDTO: Encodable, Equatable, Sendable {
    let nickname: String
}
