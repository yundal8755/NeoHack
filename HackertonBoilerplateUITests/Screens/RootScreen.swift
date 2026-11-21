import HackertonCore
import XCTest

/// 루트(홈) 화면 조작을 감싼다. 요소는 AccessibilityID로 찾는다.
@MainActor
struct RootScreen {
    let app: XCUIApplication

    var homeScreen: XCUIElement {
        app.descendants(matching: .any)[AccessibilityID.Root.homeScreen]
    }
}
