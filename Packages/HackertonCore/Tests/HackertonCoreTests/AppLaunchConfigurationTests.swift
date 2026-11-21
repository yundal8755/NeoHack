import HackertonCore
import Testing

@Suite("AppLaunchConfiguration")
struct AppLaunchConfigurationTests {
    @Test(arguments: [
        ([], .live),
        (["-mock-scenario", "loginFailure"], .live),
        (["-mock-mode"], .mock(.default)),
        (["-mock-mode", "-mock-scenario", "loginFailure"], .mock("loginFailure")),
        (["-mock-scenario", "loginFailure", "-mock-mode"], .mock("loginFailure")),
        (["-mock-mode", "-mock-scenario"], .mock(.default)),
        (["-mock-mode", "-mock-scenario", ""], .mock(.default)),
        (["-mock-mode", "-mock-scenario", "-other"], .mock(.default)),
    ] as [([String], AppLaunchConfiguration.DataMode)])
    func 실행_인자로_데이터_모드를_정한다(arguments: [String], expected: AppLaunchConfiguration.DataMode) {
        #expect(AppLaunchConfiguration(arguments: arguments).dataMode == expected)
    }

    @Test(arguments: [
        AppLaunchConfiguration.DataMode.live,
        .mock(.default),
        .mock("loginFailure"),
    ])
    func launchArguments로_만든_인자는_같은_모드로_읽힌다(mode: AppLaunchConfiguration.DataMode) {
        let arguments = AppLaunchConfiguration.launchArguments(for: mode)

        #expect(AppLaunchConfiguration(arguments: arguments).dataMode == mode)
    }
}
