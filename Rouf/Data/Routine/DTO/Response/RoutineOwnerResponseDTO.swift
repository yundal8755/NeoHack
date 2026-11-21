import Foundation

nonisolated struct RoutineOwnerResponseDTO: Decodable, Equatable, Sendable {
    let userId: String?
    let nickname: String?
    let profileImageUrl: String?
}
