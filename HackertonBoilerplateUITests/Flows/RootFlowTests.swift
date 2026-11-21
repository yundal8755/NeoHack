import HackertonCore
import XCTest

/// 핵심 흐름 UI 테스트. 항상 목 모드로 실행해 네트워크와 Keychain을 쓰지 않는다.
final class RootFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func test_루틴_카드에서_오른쪽으로_밀어도_상세가_열리지_않는다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()
        let card = app.buttons[AccessibilityID.Home.routine(0)]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        let start = card.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
        let end = card.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        let screen = RootScreen(app: app)
        XCTAssertTrue(screen.routineCreateEntry.waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements[AccessibilityID.RoutineDetail.screen].exists)
    }

    @MainActor
    func test_루틴_카드를_조금만_밀다_놓아도_상세가_열리지_않는다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()
        let card = app.buttons[AccessibilityID.Home.routine(0)]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        let start = card.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        let end = card.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        XCTAssertFalse(app.otherElements[AccessibilityID.RoutineDetail.screen].waitForExistence(timeout: 2))
        XCTAssertTrue(card.exists)
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
    func test_홈을_왼쪽으로_밀면_마이프로필이_열린다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()
        let screen = RootScreen(app: app)
        XCTAssertTrue(screen.homeScreen.waitForExistence(timeout: 10))
        screen.homeScreen.swipeLeft()
        XCTAssertTrue(app.otherElements[AccessibilityID.MyProfile.screen].waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.TopBar.leadingButton].tap()
        XCTAssertTrue(app.buttons[AccessibilityID.Home.createButton].waitForExistence(timeout: 5))
    }

    @MainActor
    func test_마이프로필을_오른쪽으로_밀면_홈으로_돌아온다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()
        let screen = RootScreen(app: app)
        XCTAssertTrue(screen.homeScreen.waitForExistence(timeout: 10))
        screen.homeScreen.swipeLeft()
        XCTAssertTrue(waitForHome(in: app, onScreen: false))

        // 가장자리가 아닌 화면 안쪽에서 밀어도 홈을 끌어올 수 있어야 한다.
        let start = screen.homeScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        let end = screen.homeScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)

        XCTAssertTrue(waitForHome(in: app, onScreen: true))
        XCTAssertFalse(app.otherElements[AccessibilityID.RoutineDetail.screen].exists)
    }

    @MainActor
    func test_마이프로필을_조금만_밀면_홈으로_돌아오지_않는다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()
        let screen = RootScreen(app: app)
        XCTAssertTrue(screen.homeScreen.waitForExistence(timeout: 10))
        screen.homeScreen.swipeLeft()
        XCTAssertTrue(waitForHome(in: app, onScreen: false))

        let start = screen.homeScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        let end = screen.homeScreen.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)

        XCTAssertFalse(waitForHome(in: app, onScreen: true, timeout: 2))
        XCTAssertFalse(app.otherElements[AccessibilityID.RoutineDetail.screen].exists)
        XCTAssertTrue(waitForHome(in: app, onScreen: false, timeout: 2))
    }

    @MainActor
    func test_프로필_편집을_누르면_준비_중_안내가_보인다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()
        let edit = app.buttons[AccessibilityID.MyProfile.editButton]
        app.buttons[AccessibilityID.TopBar.trailingButton].tap()
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        XCTAssertTrue(app.staticTexts["프로필 편집 화면은 준비 중입니다."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields[AccessibilityID.MyProfile.editNickname].exists)
    }

    @MainActor
    func test_프로필에서_루틴_상세를_열고_뒤로_가면_프로필로_돌아온다() {
        let app = XCUIApplication()
        app.launchArguments = AppLaunchConfiguration.launchArguments(for: .mock(.default))
        app.launch()
        let screen = RootScreen(app: app)
        XCTAssertTrue(screen.homeScreen.waitForExistence(timeout: 10))
        screen.homeScreen.swipeLeft()
        let row = app.buttons["myProfile.routine.0"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.RoutineDetail.allCommentsButton].waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.TopBar.leadingButton].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.TopBar.leadingButton].tap()
        XCTAssertTrue(app.buttons[AccessibilityID.Home.createButton].waitForExistence(timeout: 5))
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

    /// 홈 카드가 화면 안에 있는지(또는 왼쪽 밖으로 다 나갔는지)를 홈의 만들기 버튼 위치로 확인한다.
    /// 홈과 마이프로필은 화면 밖으로 밀려 있어도 접근성 트리에 남아 `exists`가 항상 참이고,
    /// 프로필을 다녀온 뒤에는 실제로는 눌리는 홈 버튼도 `isHittable`이 거짓으로 나와서 둘 다 쓸 수 없다.
    @MainActor
    private func waitForHome(in app: XCUIApplication, onScreen: Bool, timeout: TimeInterval = 5) -> Bool {
        let create = app.buttons[AccessibilityID.Home.createButton]
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if create.exists {
                let frame = create.frame
                if onScreen ? frame.minX >= 0 : frame.maxX <= 0 { return true }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return false
    }
}
