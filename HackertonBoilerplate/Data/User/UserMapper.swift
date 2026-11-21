import Foundation

enum UserMapper {
    static func map(_ dto: UserProfileResponseDTO) -> UserProfile {
        UserProfile(
            profileImageUrl: dto.profileImageUrl,
            nickname: dto.nickname,
            introduce: dto.introduce,
            name: dto.name,
            phoneNumber: dto.phoneNumber,
            level: dto.level,
            temperature: dto.temperature,
            lat: dto.lat,
            lon: dto.lon
        )
    }
}
