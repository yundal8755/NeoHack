import RoufCore
import SnapshotTesting
import SwiftUI
import Testing
@testable import Rouf

/// 화면 스냅샷. MVI 화면은 State별로 Store를 만들어 한 장씩 찍는다.
///
/// ```swift
/// @Test(arguments: [("idle", LoginReducer.State()), ("loading", .init(isLoading: true))])
/// func loginView(name: String, state: LoginReducer.State) {
///     let store = StoreOf<LoginReducer>(state: state, reducer: LoginReducer(repository: MockAuthRepository()))
///     assertSnapshot(of: LoginView(store: store), as: .screen, named: name)
/// }
/// ```
@MainActor
@Suite(.snapshots(record: .missing))
struct RootViewSnapshotTests {
    @Test func rootView() {
        assertSnapshot(of: RootView(container: AppContainer(configuration: .init(dataMode: .mock(.default)))), as: .screen)
    }
}
