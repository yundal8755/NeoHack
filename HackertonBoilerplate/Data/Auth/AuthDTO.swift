import Foundation

struct AuthLoginRequestDTO: Encodable, Equatable, Sendable {
    let loginId: String
    let password: String
}

struct AuthLoginEnvelopeDTO: Decodable, Equatable, Sendable {
    let code: Int
    let message: String
    let data: AuthLoginResponseDTO?

    var success: Bool {
        (200..<300).contains(code)
    }
}

struct AuthLoginResponseDTO: Decodable, Equatable, Sendable {
    let accessToken: String
}
