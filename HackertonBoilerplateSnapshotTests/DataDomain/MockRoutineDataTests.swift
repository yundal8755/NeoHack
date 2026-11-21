import HackertonCore
@testable import HackertonBoilerplate
import Testing

struct MockRoutineDataTests {
    @Test func 목록과_댓글의_ID와_개수가_일치한다() {
        let home = MockRoutineData.home
        #expect(home.routines.count == 12)
        #expect(Set(home.routines.map(\.id)).count == 12)
        for routine in home.routines {
            #expect(routine.detail.commentCount == routine.detail.comments.count)
            #expect(Set(routine.detail.comments.map(\.id)).count == routine.detail.comments.count)
            #expect(routine.detail.comments.allSatisfy { (1...50).contains($0.content.count) })
            #expect(!routine.detail.steps.isEmpty)
        }
    }

    @Test func 프리뷰_상태는_서로_영향을_주지_않는다() {
        var edited = MockRoutineData.detail
        edited.comments.removeAll()
        #expect(MockRoutineData.detail.comments.count == 12)
        #expect(MockRoutineData.noComments.commentCount == 0)
        #expect(MockRoutineData.ownRoutine.isOwner)
        #expect(MockRoutineData.participatingRoutine.participation == .joined)
        #expect(MockRoutineData.completedRoutine.participation == .completed)
        #expect(MockRoutineData.editingComment.editingCommentID != nil)
        #expect(MockRoutineData.emptyHome.routines.isEmpty)
    }
}
