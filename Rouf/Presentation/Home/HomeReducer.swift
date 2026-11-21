import Foundation
import MVICore

nonisolated struct HomeReducer: Reducer {
    let repository: (any RoutineRepository)?
    let authorID: String?
    let participantID: String?

    init(repository: (any RoutineRepository)? = nil, authorID: String? = nil, participantID: String? = nil) {
        self.repository = repository
        self.authorID = authorID
        self.participantID = participantID
    }

    struct Routine: Equatable, Identifiable {
        let id: String
        let nickname: String
        let introduction: String
        let createdAt: Date?
        var avatarURL: URL? = nil
        var thumbnailURL: URL? = nil
        var participantCount: Int? = nil
        var isServerRow = false
        var resultParticipantID: String? = nil
        var detail: RoutineDetailReducer.State

        init(id: String, nickname: String, introduction: String, createdAt: Date?, detail: RoutineDetailReducer.State) {
            self.id = id
            self.nickname = nickname
            self.introduction = introduction
            self.createdAt = createdAt
            self.detail = detail
        }
    }

    enum Sort: String, CaseIterable {
        case latest = "최신순"
        case likes = "인기순"
        case participation = "참여순"
    }

    struct State: Equatable {
        var routines: [Routine]
        var sort: Sort
        var isLoading = false
        var error: String?
        var cursor: String?
        var loaded = false
        var totalCount: Int?

        init(routines: [Routine] = [], sort: Sort = .latest) {
            self.routines = routines
            self.sort = sort
        }

    }

    enum Action {
        case appeared
        case refresh
        case sortChanged(Sort)
        case nextPage(String)
        case received(RoutinePageEntity, append: Bool)
        case failed(String)
        case removed(String)
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            guard !state.loaded, !state.isLoading else { return .none }
            return load(&state)
        case .refresh:
            return load(&state)
        case .sortChanged(let sort):
            guard state.sort != sort else { return .none }
            state.sort = sort
            state.routines = []
            return load(&state)
        case .nextPage(let id):
            guard !state.isLoading, state.error == nil, id == state.routines.last?.id,
                let cursor = state.cursor
            else { return .none }
            return load(&state, cursor: cursor)
        case .received(let page, let append):
            let rows = (page.routines ?? []).map { entity in
                var row = Routine(
                    id: entity.id, nickname: entity.owner?.nickname ?? "작성자",
                    introduction: entity.content ?? "", createdAt: entity.createdAt,
                    detail: .init(title: entity.title, likeCount: Int(entity.likeCount ?? 0)))
                row.avatarURL = entity.owner?.profileImageURL
                row.thumbnailURL = entity.thumbnailURL
                row.participantCount = entity.participantCount.map(Int.init)
                row.isServerRow = true
                row.resultParticipantID = entity.participation == .completed ? participantID : nil
                if entity.participation == .completed { row.detail.participation = .completed }
                else if entity.participation == .joined { row.detail.participation = .joined }
                return row
            }
            state.totalCount = page.totalCount
            let previousCursor = state.cursor
            if !append { state.routines = [] }
            var ids = Set(state.routines.map(\.id))
            state.routines += rows.filter { ids.insert($0.id).inserted }
            state.cursor =
                page.hasNext == true && (!append || previousCursor != page.nextCursor) ? page.nextCursor : nil
            state.loaded = true
            state.isLoading = false
        case .failed(let message):
            state.error = message
            state.isLoading = false
        case .removed(let id):
            state.routines.removeAll { $0.id == id }
            return load(&state)
        }
        return .none
    }

    private func load(_ state: inout State, cursor: String? = nil) -> Effect<Action> {
        guard let repository else { return .none }
        if cursor == nil { state.cursor = nil }
        state.isLoading = true
        state.error = nil
        let sort: RoutineListQuery.Sort =
            switch state.sort {
            case .latest: .latest
            case .likes: .likes
            case .participation: .participants
            }
        let query = RoutineListQuery(sort: sort, authorID: authorID, participantID: participantID, cursor: cursor)
        return .run { send in
            do {
                let page = try await repository.list(query: query)
                try Task.checkCancellation()
                await send(.received(page, append: cursor != nil))
            } catch { await send(.failed(error.localizedDescription)) }
        }.cancelTask(id: "list")
    }
}
