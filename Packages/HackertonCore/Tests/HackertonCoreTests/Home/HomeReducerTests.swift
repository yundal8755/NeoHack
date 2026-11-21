import Foundation
import HackertonCore
import Testing

struct HomeReducerTests {
    @Test func 정렬은_원본_목록을_보존하고_동률은_ID로_정한다() {
        let rows = [(3, 10, 10), (2, 20, 5), (1, 10, 10)].map { id, date, likes in
            HomeReducer.Routine(id: id, nickname: "닉네임", introduction: "소개", createdAt: Date(timeIntervalSince1970: Double(date)), detail: .init(title: "루틴", likeCount: likes))
        }
        var state = HomeReducer.State(routines: rows)
        #expect(state.sortedRoutines.map(\.id) == [2, 1, 3])
        _ = HomeReducer().reduce(&state, with: .sortChanged(.likes))
        #expect(state.sortedRoutines.map(\.id) == [1, 3, 2])
        #expect(state.routines == rows)
        #expect(HomeReducer.State().sortedRoutines.isEmpty)
    }
}
