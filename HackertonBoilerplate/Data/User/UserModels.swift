import Foundation

struct UserProfile: Equatable, Sendable {
    let profileImageUrl: String
    let nickname: String
    let introduce: String
    let name: String
    let phoneNumber: String
    let level: Int
    let temperature: Double
    let lat: Double
    let lon: Double
}
