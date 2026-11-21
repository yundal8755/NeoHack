import Combine
import Foundation

public typealias StoreOf<R: Reducer> = Store<R.State, R.Action>

@MainActor
public final class Store<State, Action>: ObservableObject {
    @Published public private(set) var state: State

    private let reducer: any Reducer<State, Action>
    private var taskMap: [_CancelID: Task<Void, Never>] = [:]

    public init(state: State, reducer: any Reducer<State, Action>) {
        self.state = state
        self.reducer = reducer
    }

    deinit {
        taskMap.values.forEach { $0.cancel() }
    }

    public func send(_ action: Action) {
        let effect = reducer.reduce(&state, with: action)
        handleEffect(effect)
    }
}

extension Store {
    private func handleEffect(_ effect: Effect<Action>) {
        if case let .run(priority, task) = effect.caseOf {
            let taskToStore = Task(priority: priority) { [weak self] in
                await task { newAction in
                    if Task.isCancelled { return }

                    await MainActor.run {
                        self?.send(newAction)
                    }
                }
            }

            if let taskID = effect.taskID {
                cancelTasks(matching: taskID)
                taskMap[taskID] = taskToStore
            }
        }

        if case .cancel = effect.caseOf {
            guard let taskID = effect.taskID else { return }
            cancelTasks(matching: taskID)
        }
    }

    /// _CancelID는 생성될 때마다 UUID가 달라서 키로 바로 찾을 수 없다. 사용자가 지정한 id로 비교한다.
    private func cancelTasks(matching taskID: _CancelID) {
        let matchingKeys = taskMap.keys.filter { $0.id == taskID.id }
        matchingKeys.forEach { key in
            taskMap[key]?.cancel()
            taskMap.removeValue(forKey: key)
        }
    }
}
