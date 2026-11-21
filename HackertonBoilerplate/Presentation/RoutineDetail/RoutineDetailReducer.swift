import Foundation
import MVICore

nonisolated struct RoutineDetailReducer: Reducer {
    let id: String?
    let userID: String?
    let resultParticipantID: String?
    let routines: (any RoutineRepository)?
    let comments: (any RoutineCommentRepository)?

    init(
        id: String? = nil, userID: String? = nil, resultParticipantID: String? = nil, routines: (any RoutineRepository)? = nil,
        comments: (any RoutineCommentRepository)? = nil
    ) {
        self.id = id
        self.userID = userID
        self.resultParticipantID = resultParticipantID
        self.routines = routines
        self.comments = comments
    }

    struct Step: Equatable, Identifiable, Sendable {
        let id: String
        let time: String
        let title: String
        let content: String
        let imageURL: URL?

        init(id: String, time: String, title: String, content: String, imageURL: URL? = nil) {
            self.id = id
            self.time = time
            self.title = title
            self.content = content
            self.imageURL = imageURL
        }
    }

    struct Comment: Equatable, Identifiable, Sendable {
        let id: String
        let nickname: String
        let dateText: String
        var content: String
        var isMine: Bool = false
        var avatarURL: URL? = nil

        init(id: String, nickname: String, dateText: String, content: String) {
            self.id = id
            self.nickname = nickname
            self.dateText = dateText
            self.content = content
        }
    }

    struct State: Equatable {
        var title: String
        var introduction: String?
        var originalAuthorNickname: String?
        var authorNickname: String?
        var authorImageURL: URL?
        var createdAt: Date?

        var navigationTitle: String {
            if isParticipationResult, let originalAuthorNickname, let authorNickname {
                return "\(originalAuthorNickname)의 하루: \(authorNickname)"
            }
            if !isParticipationResult, let authorNickname {
                return "\(authorNickname)의 하루"
            }
            return title
        }
        var entity: RoutineDetailEntity?

        var canEdit: Bool {
            let ownsContent = isParticipationResult ? isParticipationOwner : isOwner
            return ownsContent && entity != nil && !isBusy && !isLoading
        }
        var steps: [Step]
        var comments: [Comment]
        var isLiked = false
        var likeCount: Int
        var commentCount: Int
        var participatingCount: Int
        var completedCount: Int
        var commentDraft = ""
        var notice: String?
        var editingCommentID: String?
        var participation = Participation.notJoined
        var isOwner = false
        var isDeleted = false
        var isLoading = false
        var isBusy = false
        var loaded = false
        var loadError: String?
        var isLive = false
        var isParticipationResult = false
        var isParticipationOwner = false

        init(
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

        var canSubmitComment: Bool {
            !commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum Participation: String, Equatable {
        case notJoined = "참여하기"
        case joined = "참여 중"
        case completed = "참여 완료"
    }

    enum Action {
        case load
        case loaded(RoutineDetailEntity, [RoutineCommentEntity], RoutineInteractions)
        case sourceAuthorReceived(String)
        case loadFailed(String)
        case interactionUpdated(RoutineInteractions)
        case commentSaved(RoutineCommentEntity)
        case commentRemoved(String)
        case routineRemoved
        case mutationFailed(String)
        case leaveTapped
        case editComment(String)
        case cancelEditing
        case deleteComment(String)
        case deleteRoutine
        case deleteParticipationResult
        case commentChanged(String)
        case submitCommentTapped
        case likeTapped
        case participateTapped
        case moreTapped
        case noticeDismissed
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .load:
            guard !state.isLoading, !state.isBusy, let id, let routines, let comments else { return .none }
            state.isLoading = true
            state.loadError = nil
            return .run { send in
                do {
                    if resultParticipantID != nil {
                        async let source = routines.detail(id: id)
                        async let result = fetchDetail(routines, id: id)
                        let (original, detail) = try await (source, result)
                        await send(.sourceAuthorReceived(original.owner?.nickname ?? "작성자"))
                        await send(.loaded(detail, [], .init(likeCount: 0, likedByMe: false,
                            inProgressCount: 0, completedCount: 0, participation: .completed)))
                        return
                    }
                    async let detail = fetchDetail(routines, id: id)
                    async let thread = comments.list(routineID: id)
                    async let interactions = routines.interactions(id: id, change: nil)
                    try await send(.loaded(detail, thread, interactions))
                } catch { await send(.loadFailed(error.localizedDescription)) }
            }.cancelTask(id: "detail")
        case .loaded(let detail, let comments, let interactions):
            state.isLoading = false
            state.loaded = true
            state.entity = detail
            state.title = detail.title
            state.introduction = detail.content
            state.authorNickname = detail.owner?.nickname
            state.authorImageURL = detail.owner?.profileImageURL
            state.createdAt = detail.createdAt
            state.isOwner = resultParticipantID == nil && (userID.map { detail.owner?.id == $0 } ?? false)
            state.isParticipationOwner = resultParticipantID != nil && resultParticipantID == userID
                && detail.owner?.id == userID
            state.steps = (detail.cards ?? []).enumerated().map { index, card in
                Step(
                    id: card.id ?? "legacy-\(index)", time: card.time, title: card.title,
                    content: card.content ?? "", imageURL: card.imageURL)
            }
            state.comments = comments.map(Self.comment)
            state.commentCount = state.comments.count
            apply(interactions, to: &state)
        case .sourceAuthorReceived(let title):
            state.originalAuthorNickname = title
        case .loadFailed(let message):
            state.isLoading = false
            state.loadError = message
        case .commentChanged(let text):
            guard !state.isBusy else { return .none }
            state.commentDraft = String(text.prefix(50))
        case .submitCommentTapped:
            guard !state.isBusy, state.canSubmitComment, let id, let comments else { return .none }
            let content = state.commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            let commentID = state.editingCommentID
            return mutate(&state) {
                let saved: RoutineCommentEntity
                if let commentID {
                    saved = try await comments.update(routineID: id, commentID: commentID, content: content)
                } else {
                    saved = try await comments.create(routineID: id, content: content)
                }
                return .commentSaved(saved)
            }
        case .likeTapped:
            return interaction(&state, state.isLiked ? .unlike : .like)
        case .participateTapped:
            guard !state.isOwner, state.participation != .completed else { return .none }
            guard state.participation == .notJoined else { return .none }
            return interaction(&state, .join)
        case .leaveTapped:
            guard state.participation == .joined else { return .none }
            return interaction(&state, .leave)
        case .editComment(let id):
            guard !state.isBusy, let comment = state.comments.first(where: { $0.id == id && $0.isMine }) else { break }
            state.editingCommentID = id
            state.commentDraft = comment.content
        case .cancelEditing:
            guard !state.isBusy else { break }
            state.editingCommentID = nil
            state.commentDraft = ""
        case .deleteComment(let commentID):
            guard let id, let comments, state.comments.contains(where: { $0.id == commentID && $0.isMine }) else {
                break
            }
            return mutate(&state) {
                try await comments.delete(routineID: id, commentID: commentID)
                return .commentRemoved(commentID)
            }
        case .deleteParticipationResult:
            guard state.isParticipationOwner, let id, let resultParticipantID, let routines else { break }
            return mutate(&state) {
                try await routines.deleteParticipationResult(routineID: id, participantID: resultParticipantID)
                return .routineRemoved
            }
        case .deleteRoutine:
            guard state.isOwner, let id, let routines else { break }
            return mutate(&state) {
                try await routines.delete(id: id)
                return .routineRemoved
            }
        case .interactionUpdated(let value):
            state.isBusy = false
            apply(value, to: &state)
        case .commentSaved(let value):
            state.isBusy = false
            var comment = Self.comment(value)
            comment.isMine = true
            if let index = state.comments.firstIndex(where: { $0.id == value.id }) {
                state.comments[index] = comment
            } else {
                state.comments.append(comment)
            }
            state.commentCount = state.comments.count
            state.commentDraft = ""
            state.editingCommentID = nil
        case .commentRemoved(let id):
            state.isBusy = false
            state.comments.removeAll { $0.id == id }
            state.commentCount = state.comments.count
            if state.editingCommentID == id {
                state.editingCommentID = nil
                state.commentDraft = ""
            }
        case .routineRemoved:
            state.isBusy = false
            state.isDeleted = true
        case .mutationFailed(let message):
            state.isBusy = false
            state.notice = message
        case .moreTapped:
            break
        case .noticeDismissed:
            state.notice = nil
        }
        return .none
    }

    private func fetchDetail(_ repository: any RoutineRepository, id: String) async throws -> RoutineDetailEntity {
        if let resultParticipantID {
            return try await repository.participationResult(id: id, participantID: resultParticipantID)
        }
        return try await repository.detail(id: id)
    }

    private func mutate(_ state: inout State, _ operation: @escaping () async throws -> Action) -> Effect<Action> {
        guard state.loaded, !state.isBusy, !state.isLoading else { return .none }
        state.isBusy = true
        return .run { send in
            do { await send(try await operation()) } catch { await send(.mutationFailed(error.localizedDescription)) }
        }.cancelTask(id: "mutation")
    }

    private func interaction(_ state: inout State, _ change: RoutineInteractions.Change) -> Effect<Action> {
        guard let id, let routines else { return .none }
        return mutate(&state) { .interactionUpdated(try await routines.interactions(id: id, change: change)) }
    }

    private func apply(_ value: RoutineInteractions, to state: inout State) {
        state.isLiked = value.likedByMe
        state.likeCount = value.likeCount
        state.participatingCount = value.inProgressCount
        state.completedCount = value.completedCount
        state.participation =
            switch value.participation {
            case .notJoined: .notJoined
            case .joined: .joined
            case .completed: .completed
            }
    }

    private static func comment(_ entity: RoutineCommentEntity) -> Comment {
        var result = Comment(
            id: entity.id, nickname: entity.authorNickname ?? "작성자",
            dateText: entity.createdAt?.formatted(date: .numeric, time: .shortened) ?? "",
            content: entity.content)
        result.isMine = entity.isMine == true
        result.avatarURL = entity.profileImageURL
        return result
    }
}
