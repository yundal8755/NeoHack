import Foundation
import MVICore

nonisolated struct RoutineParticipantsReducer: Reducer {
    let routineID: String
    let repository: any RoutineRepository

    struct Row: Equatable, Identifiable {
        let id: String
        let summary: RoutineParticipationResults.Summary
    }

    struct State: Equatable {
        var rows: [Row] = []
        var totalCount = 0
        var isLoading = false
        var loaded = false
        var error: String?
    }

    enum Action {
        case appeared
        case refresh
        case received(RoutineParticipationResults)
        case failed(String)
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            guard !state.loaded else { return .none }
            return load(&state)
        case .refresh:
            return load(&state)
        case let .received(result):
            state.isLoading = false
            let summaries = result.results ?? []
            guard summaries.allSatisfy({ $0.participant != nil }) else {
                state.error = "참여자 정보가 누락됐어요. 다시 시도해 주세요."
                return .none
            }
            var ids = Set<String>()
            state.rows = summaries.compactMap { summary in
                guard let id = summary.participant?.id, ids.insert(id).inserted else { return nil }
                return Row(id: id, summary: summary)
            }
            state.totalCount = result.totalCount ?? state.rows.count
            state.loaded = true
        case let .failed(message):
            state.isLoading = false
            state.error = message
        }
        return .none
    }

    private func load(_ state: inout State) -> Effect<Action> {
        guard !state.isLoading else { return .none }
        state.isLoading = true
        state.error = nil
        return .run { send in
            do { await send(.received(try await repository.participationResults(routineID: routineID))) }
            catch { await send(.failed(error.localizedDescription)) }
        }.cancelTask(id: "participants")
    }
}
