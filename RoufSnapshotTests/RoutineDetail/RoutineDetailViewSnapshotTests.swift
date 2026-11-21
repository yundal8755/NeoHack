import RoufCore
import RoufMocks
import MVICore
import SnapshotTesting
import SwiftUI
import Testing
@testable import Rouf

@MainActor
@Suite(.snapshots(record: .missing))
struct RoutineDetailViewSnapshotTests {
    @Test(arguments: ["populated", "empty", "draft", "owner"])
    func routineDetailView(stateName: String) {
        var state = stateName == "empty"
            ? RoutineDetailReducer.State(title: "루틴 상세")
            : MockRoutineData.detail
        if stateName == "draft" { state.commentDraft = "이 루틴을 함께 해보고 싶어요." }
        if stateName == "owner" { state.isOwner = true }
        let view = RoutineDetailView(store: StoreOf<RoutineDetailReducer>(
            state: state,
            reducer: RoutineDetailReducer()
        ))
        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 402, height: 980),
                traits: .init(userInterfaceStyle: .light)
            ),
            named: stateName
        )
    }
}
