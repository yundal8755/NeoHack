import SnapshotTesting
import SwiftUI
import Testing
@testable import Rouf

/// 홈을 오른쪽으로 밀 때 드러나는 루틴 만들기 안내의 상태별 모습.
@MainActor
@Suite(.snapshots(record: .missing))
struct RoutineCreateSwipeHintSnapshotTests {
    @Test(arguments: [
        ("pulling", 0.5, false),
        ("ready", 1.0, true),
    ])
    func routineCreateSwipeHint(name: String, progress: Double, isReady: Bool) {
        let view = RoutineCreateSwipeHint(progress: progress, isReady: isReady)
            .frame(width: 160, height: 160)
        assertSnapshot(of: view, as: .component, named: name)
    }
}
