import Foundation
@testable import Rouf
import Testing

struct RoutineDetailReducerTests {
    @Test(arguments: [
        (true, false, true),
        (false, true, true),
        (false, false, false),
    ])
    func 더보기는_본인_루틴이나_본인_참여_기록에만_보여준다(isOwner: Bool, isParticipationOwner: Bool, expected: Bool) {
        var state = RoutineDetailReducer.State(title: "김햄찌의 하루")
        state.isOwner = isOwner
        state.isParticipationOwner = isParticipationOwner
        #expect(state.showsMoreMenu == expected)
    }
}
