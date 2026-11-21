import Foundation

/// 서비스 이름처럼 여러 화면에서 같은 값을 써야 하는 브랜드 정보.
/// 런치 스크린의 워드마크(`LaunchWordmark`)와 홈 화면 앱 이름(Info.plist `CFBundleDisplayName`)도 같은 이름을 쓴다.
enum AppBrand {
    static let serviceName = "Rouf"
}
