import Foundation

enum AppRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
    static let pill: CGFloat = 999

    // MARK: - Figma 컴포넌트 모서리

    /// 입력창.
    static let input: CGFloat = 8
    /// 버튼, 이미지 영역.
    static let button: CGFloat = 12
    /// 바텀시트 위쪽 모서리.
    static let sheet: CGFloat = 20
    /// 옆으로 밀려나는 화면 전체 카드. 기기 화면 모서리와 비슷하게 둥글게 한다.
    static let slidingScreen: CGFloat = 44
}
