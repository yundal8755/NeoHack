import HackertonCore
import MVICore
import SnapshotTesting
import SwiftUI
import Testing
@testable import HackertonBoilerplate

@MainActor
@Suite(.snapshots(record: .missing))
struct HomeViewSnapshotTests {
    @Test(arguments: ["populated", "empty"])
    func homeView(stateName: String) {
        let store = StoreOf<HomeReducer>(
            state: stateName == "empty" ? .init() : HomePreview.state,
            reducer: HomeReducer()
        )
        assertSnapshot(of: HomeView(store: store), as: .screen, named: stateName)
    }
}
