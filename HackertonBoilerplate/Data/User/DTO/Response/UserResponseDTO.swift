import Foundation

nonisolated struct UserResponseDTO: Decodable, Equatable, Sendable {
    let publicId: String?
    let nickname: String?
    let profileImagePublicId: String?
}
