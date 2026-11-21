import HackertonCore
import XCTest

/// 핵심 흐름 UI 테스트. 항상 목 모드로 실행해 네트워크와 Keychain을 쓰지 않는다.
final class RootFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func test_목_모드로_실행하면_홈에서_설정_탭으로_이동한다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()

        let screen = RootScreen(app: app)
        XCTAssertTrue(screen.homeScreen.waitForExistence(timeout: 10))

        screen.openSettingsTab()
        XCTAssertTrue(screen.settingsScreen.waitForExistence(timeout: 5))
    }
}
