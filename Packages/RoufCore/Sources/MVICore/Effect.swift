import Foundation

public struct Effect<Action>: @unchecked Sendable {
    package let caseOf: EffectCase
    package let taskID: _CancelID?

    package init(caseOf: EffectCase, taskID: AnyHashable? = nil) {
        self.caseOf = caseOf

        if let taskID {
            self.taskID = _CancelID(id: taskID)
        } else {
            self.taskID = nil
        }
    }

    package enum EffectCase {
        case none
        case run(TaskPriority? = nil, (_ send: @escaping (Action) async -> Void) async -> Void)
        case cancel
    }

    public static var none: Self {
        Self(caseOf: .none)
    }

    public static func run(
        priority: TaskPriority? = nil,
        task: @escaping (_ send: @escaping (Action) async -> Void) async -> Void
    ) -> Self {
        Self(caseOf: .run(priority, task))
    }

    public static func cancel(id: some Hashable) -> Self {
        Self(caseOf: .cancel, taskID: id)
    }

    public func cancelTask(id: some Hashable) -> Self {
        switch caseOf {
        case .none:
            .none
        case .run(let taskPriority, let action):
            Self(caseOf: .run(taskPriority, action), taskID: id)
        case .cancel:
            .none
        }
    }
}
