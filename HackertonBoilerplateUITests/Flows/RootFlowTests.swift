import HackertonCore
import XCTest

/// 핵심 흐름 UI 테스트. 항상 목 모드로 실행해 네트워크와 Keychain을 쓰지 않는다.
final class RootFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func test_목_모드로_실행하면_홈_화면이_보인다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()

        let screen = RootScreen(app: app)
        XCTAssertTrue(screen.homeScreen.waitForExistence(timeout: 10))
    }

    @MainActor
    func test_홈을_오른쪽으로_밀면_루틴_만들기가_열린다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()

        let screen = RootScreen(app: app)
        XCTAssertTrue(screen.homeScreen.waitForExistence(timeout: 10))

        screen.homeScreen.swipeRight()

        XCTAssertTrue(screen.routineCreateEntry.waitForExistence(timeout: 5))
    }

    @MainActor
    func test_홈을_조금만_밀면_루틴_만들기가_열리지_않는다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()

        let screen = RootScreen(app: app)
        XCTAssertTrue(screen.homeScreen.waitForExistence(timeout: 10))

        let start = screen.homeScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        let end = screen.homeScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)

        XCTAssertFalse(screen.routineCreateEntry.waitForExistence(timeout: 2))
    }
}
