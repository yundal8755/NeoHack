import Foundation
import MVICore

/// UI 전용 표시 상태. 서버 Entity와 Repository가 준비되면 조회·변경 Effect를 연결한다.
public struct RoutineDetailReducer: Reducer {
    public init() {}

    public struct Step: Equatable, Identifiable, Sendable {
        public let id: Int
        public let time: String
        public let title: String
        public let content: String
        public let imageURL: URL?

        public init(id: Int, time: String, title: String, content: String, imageURL: URL? = nil) {
            self.id = id
            self.time = time
            self.title = title
            self.content = content
            self.imageURL = imageURL
        }
    }

    public struct Comment: Equatable, Identifiable, Sendable {
        public let id: Int
        public let nickname: String
        public let dateText: String
        public var content: String
        public var isMine: Bool = false

        public init(id: Int, nickname: String, dateText: String, content: String) {
            self.id = id
            self.nickname = nickname
            self.dateText = dateText
            self.content = content
        }
    }

    public struct State: Equatable {
        public var title: String
        public var steps: [Step]
        public var comments: [Comment]
        public var isLiked = false
        public var likeCount: Int
        public var commentCount: Int
        public var participatingCount: Int
        public var completedCount: Int
        public var commentDraft = ""
        public var notice: String?
        public var editingCommentID: Int?
        public var participation = Participation.notJoined
        public var isOwner = false

        public init(
            title: String,
            steps: [Step] = [],
            comments: [Comment] = [],
            likeCount: Int = 0,
            commentCount: Int = 0,
            participatingCount: Int = 0,
            completedCount: Int = 0
        ) {
            self.title = title
            self.steps = steps
            self.comments = comments
            self.likeCount = likeCount
            self.commentCount = commentCount
            self.participatingCount = participatingCount
            self.completedCount = completedCount
        }

        public var canSubmitComment: Bool {
            !commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    public enum Participation: String, Equatable {
        case notJoined = "참여하기"
        case joined = "참여 중"
        case completed = "참여 완료"
    }

    public enum Action {
        case editComment(Int)
        case cancelEditing
        case deleteComment(Int)
        case commentChanged(String)
        case submitCommentTapped
        case likeTapped
        case participateTapped
        case noticeDismissed
    }

    public func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case let .commentChanged(text):
            state.commentDraft = String(text.prefix(50))
        case .submitCommentTapped:
            guard state.canSubmitComment else { return .none }
            // shortcut: 댓글은 화면 메모리에만 저장한다. 서버 Repository 연결 시 영속 저장으로 교체한다.
            let content = state.commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if let id = state.editingCommentID {
                guard let index = state.comments.firstIndex(where: { $0.id == id && $0.isMine }) else { return .none }
                state.comments[index].content = content
                state.editingCommentID = nil
                state.commentDraft = ""
                return .none
            }
            let nextID = (state.comments.map(\.id).max() ?? 0) + 1
            state.comments.append(Comment(
                id: nextID,
                nickname: "나",
                dateText: "방금",
                content: state.commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            state.comments[state.comments.count - 1].isMine = true
            state.commentCount += 1
            state.commentDraft = ""
            state.notice = "이 댓글은 미리보기용으로만 저장돼요. 서버에는 전송되지 않았습니다."
        // shortcut: 서버 변경 API가 없어 안내만 표시한다. Repository 계약이 준비되면 Effect로 교체한다.
        case .likeTapped:
            state.notice = "좋아요는 서버 연결 후 사용할 수 있어요."
        case .participateTapped:
            switch state.participation {
            case .notJoined:
                state.participation = .joined
                state.participatingCount += 1
            case .joined:
                state.participation = .completed
                state.participatingCount = max(0, state.participatingCount - 1)
                state.completedCount += 1
            case .completed: break
            }
            state.notice = "참여 상태는 미리보기용이며 서버에는 저장되지 않습니다."
        case let .editComment(id):
            guard let comment = state.comments.first(where: { $0.id == id && $0.isMine }) else { break }
            state.editingCommentID = id
            state.commentDraft = comment.content
        case .cancelEditing:
            state.editingCommentID = nil
            state.commentDraft = ""
        case let .deleteComment(id):
            guard let index = state.comments.firstIndex(where: { $0.id == id && $0.isMine }) else { break }
            state.comments.remove(at: index)
            state.commentCount = max(0, state.commentCount - 1)
            if state.editingCommentID == id {
                state.editingCommentID = nil
                state.commentDraft = ""
            }
        case .noticeDismissed:
            state.notice = nil
        }
        return .none
    }
}
