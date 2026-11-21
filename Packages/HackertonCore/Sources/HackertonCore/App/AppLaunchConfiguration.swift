import Foundation

/// 실행 인자로 앱의 데이터 모드를 정한다.
/// UI 테스트는 `launchArguments(for:)`로 인자를 만들고, 앱은 `current`로 읽어 AppContainer에 전달한다.
public struct AppLaunchConfiguration: Equatable, Sendable {
    public enum DataMode: Equatable, Sendable {
        case live
        case mock(MockScenario)
    }

    public static let mockModeArgument = "-mock-mode"
    public static let mockScenarioArgument = "-mock-scenario"

    public let dataMode: DataMode

    public init(dataMode: DataMode) {
        self.dataMode = dataMode
    }

    public init(arguments: [String]) {
        guard arguments.contains(Self.mockModeArgument) else {
            self.init(dataMode: .live)
            return
        }

        let scenario = arguments
            .firstIndex(of: Self.mockScenarioArgument)
            .flatMap { index in arguments.indices.contains(index + 1) ? arguments[index + 1] : nil }
            .filter { $0.isEmpty == false && $0.hasPrefix("-") == false }
            .map(MockScenario.init(rawValue:))

        self.init(dataMode: .mock(scenario ?? .default))
    }

    public static var current: Self {
        Self(arguments: ProcessInfo.processInfo.arguments)
    }

    public static func launchArguments(for dataMode: DataMode) -> [String] {
        switch dataMode {
        case .live:
            []
        case let .mock(scenario):
            [mockModeArgument, mockScenarioArgument, scenario.rawValue]
        }
    }
}

/// 목 모드에서 Mock Repository가 돌려줄 응답 묶음의 이름. 기능을 추가할 때 시나리오를 확장한다.
public struct MockScenario: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public static let `default`: MockScenario = "default"

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

private extension Optional {
    func filter(_ isIncluded: (Wrapped) -> Bool) -> Wrapped? {
        flatMap { isIncluded($0) ? $0 : nil }
    }
}
