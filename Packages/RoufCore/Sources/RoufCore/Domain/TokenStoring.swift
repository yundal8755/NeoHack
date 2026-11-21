import Foundation

/// 액세스 토큰 저장소. 실제 구현(KeychainTokenStore)은 앱 타깃에 있고,
/// 테스트와 목 모드에서는 RoufMocks의 InMemoryTokenStore를 주입한다.
public protocol TokenStoring {
    var accessToken: String? { get set }
    func clear()
}
