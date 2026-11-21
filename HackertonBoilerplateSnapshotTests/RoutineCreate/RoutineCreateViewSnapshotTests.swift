import Foundation
import HackertonCore
import MVICore
import SnapshotTesting
import SwiftUI
import Testing
@testable import HackertonBoilerplate

/// 루틴 작성 화면을 State별로 찍는다. 이미지는 비동기로 디코딩하므로 회색 자리 표시 상태로 찍힌다.
@MainActor
@Suite(.snapshots(record: .missing))
struct RoutineCreateViewSnapshotTests {
    typealias Feature = RoutineCreateReducer

    static let steps: [Feature.Step] = (0..<4).map { _ in
        Feature.Step(image: RoutineImage(data: Data()), time: TimeOfDay(hour: 10, minute: 30))
    }

    static let filledSteps: [Feature.Step] = steps.map {
        var step = $0
        step.title = "아침에 지하철 타러 가요."
        step.content = "지하철 사람 너무 많아서 항상 지옥철이고.. 그냥 집에 다시 가고 싶고 그러네요...^^"
        return step
    }

    static let states: [(String, Feature.State)] = [
        ("firstStepEmpty", Feature.State(steps: steps)),
        ("secondStepFilled", Feature.State(steps: filledSteps, page: .step(1))),
        ("introductionEmpty", Feature.State(steps: filledSteps, page: .introduction)),
        (
            "introductionFilled",
            Feature.State(
                steps: filledSteps,
                page: .introduction,
                routineTitle: "김햄찌의 하루",
                routineIntroduction: "김햄찌의 하루.. 정말이지 루틴해요... 딱히 재밋는게 없네요. 그래도 한 번 공유 드려요"
            )
        ),
    ]

    @Test(arguments: states.map(\.0))
    func routineCreateView(name: String) throws {
        let state = try #require(Self.states.first { $0.0 == name }?.1)
        let store = StoreOf<Feature>(state: state, reducer: Feature())
        assertSnapshot(of: RoutineCreateView(store: store), as: .screen, named: name)
    }
}
