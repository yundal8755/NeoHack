import Foundation

protocol Reducer<State, Action> {
    associatedtype State
    associatedtype Action

    func reduce(_ state: inout State, with action: Action) -> Effect<Action>
}
