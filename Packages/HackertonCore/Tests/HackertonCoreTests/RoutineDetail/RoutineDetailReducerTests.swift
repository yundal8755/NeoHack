import Foundation
import HackertonCore
import Testing

struct RoutineDetailReducerTests {
    @Test(arguments: ["", " ", "\n\t", "댓글", "  댓글  "])
    func 댓글_작성과_공백_검증(text: String) {
        var state = RoutineDetailReducer.State(title: "루틴")
        let reducer = RoutineDetailReducer()
        _ = reducer.reduce(&state, with: .commentChanged(text))
        let valid = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        #expect(state.canSubmitComment == valid)
        _ = reducer.reduce(&state, with: .submitCommentTapped)
        #expect(state.comments.count == (valid ? 1 : 0))
        #expect(state.commentCount == state.comments.count)
        if valid {
            #expect(state.comments[0].isMine)
            #expect(state.commentDraft.isEmpty)
        }
    }

    @Test func 댓글_글자수_수정_삭제와_소유권() {
        var state = RoutineDetailReducer.State(title: "루틴", comments: [.init(id: 1, nickname: "다른 사람", dateText: "오늘", content: "댓글")], commentCount: 1)
        let reducer = RoutineDetailReducer()
        _ = reducer.reduce(&state, with: .deleteComment(1))
        _ = reducer.reduce(&state, with: .editComment(1))
        #expect(state.comments.count == 1)
        #expect(state.editingCommentID == nil)
        _ = reducer.reduce(&state, with: .commentChanged(String(repeating: "가", count: 60)))
        #expect(state.commentDraft.count == 50)
        _ = reducer.reduce(&state, with: .submitCommentTapped)
        let id = state.comments.last!.id
        _ = reducer.reduce(&state, with: .editComment(id))
        _ = reducer.reduce(&state, with: .commentChanged("수정"))
        _ = reducer.reduce(&state, with: .submitCommentTapped)
        #expect(state.comments.last?.content == "수정")
        #expect(state.commentCount == 2)
        _ = reducer.reduce(&state, with: .deleteComment(id))
        #expect(state.comments.count == 1)
        #expect(state.commentCount == 1)
    }

    @Test func 참여_상태와_루틴_삭제_권한() {
        var state = RoutineDetailReducer.State(title: "루틴", participatingCount: 3, completedCount: 10)
        let reducer = RoutineDetailReducer()
        _ = reducer.reduce(&state, with: .participateTapped)
        #expect(state.participation == .joined)
        #expect(state.participatingCount == 4)
        _ = reducer.reduce(&state, with: .participateTapped)
        _ = reducer.reduce(&state, with: .participateTapped)
        #expect(state.participation == .completed)
        #expect(state.participatingCount == 3)
        #expect(state.completedCount == 11)
        _ = reducer.reduce(&state, with: .deleteRoutine)
        #expect(!state.isDeleted)
        state.isOwner = true
        _ = reducer.reduce(&state, with: .deleteRoutine)
        #expect(state.isDeleted)
    }
}
