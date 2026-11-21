import HackertonCore
import XCTest

/// 루트 탭 화면 조작을 감싼다. 요소는 AccessibilityID로 찾는다.
@MainActor
struct RootScreen {
    let app: XCUIApplication

    var homeScreen: XCUIElement {
        app.descendants(matching: .any)[AccessibilityID.Root.homeScreen]
    }

    var settingsScreen: XCUIElement {
        app.descendants(matching: .any)[AccessibilityID.Root.settingsScreen]
    }

    @discardableResult
    func openSettingsTab() -> Self {
        // 시스템 탭 바 버튼은 identifier를 붙일 수 없어서 라벨로 찾는다.
        app.tabBars.buttons["설정"].tap()
        return self
    }
}
