import Foundation

/// View의 `accessibilityIdentifier`와 XCUITest가 함께 쓰는 식별자.
/// 화면을 추가하면 같은 이름의 하위 enum을 만들고 `<화면>.<요소>` 형식으로 값을 정한다.
public enum AccessibilityID {
    public enum Root {
        public static let homeScreen = "root.homeScreen"
        public static let settingsScreen = "root.settingsScreen"
    }
}
