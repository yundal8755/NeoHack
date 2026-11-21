import Foundation

nonisolated struct RoutineOwnerEntity: Equatable, Sendable {
    let id: String
    let nickname: String?
    let profileImageURL: URL?
}
