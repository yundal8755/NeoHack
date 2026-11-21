import Foundation

enum AuthMapper {
    static func map(_ dto: AuthLoginResponseDTO) -> LoginResult {
        LoginResult(accessToken: dto.accessToken)
    }
}
