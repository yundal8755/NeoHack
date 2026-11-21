@testable import HackertonBoilerplate
import Testing

struct MyProfileReducerTests {
    @Test func 탭을_바꾸면_해당_목록을_보여준다() {
        var state = MockRoutineData.profile
        let reducer = MyProfileReducer()
        #expect(state.selectedTab == .mine)
        #expect(state.visibleRoutines.count == 3)
        #expect(state.visibleRoutines.allSatisfy { $0.detail.isOwner })
        _ = reducer.reduce(&state, with: .tabSelected(.participating))
        #expect(state.visibleRoutines == state.participatingRoutines)
        #expect(state.visibleRoutines.count == 5)
        #expect(state.visibleRoutines.allSatisfy { !$0.detail.isOwner && $0.detail.participation != .notJoined })
        _ = reducer.reduce(&state, with: .editTapped)
        #expect(state.notice == "프로필 편집 화면은 준비 중입니다.")
        #expect(state.edit == nil)
        _ = reducer.reduce(&state, with: .noticeDismissed)
        #expect(state.notice == nil)
    }
}
