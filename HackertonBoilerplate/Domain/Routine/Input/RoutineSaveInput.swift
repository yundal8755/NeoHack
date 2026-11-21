import Foundation

nonisolated struct RoutineSaveInput: Equatable, Sendable {
    let title: String
    let content: String?
    let cards: [RoutineCardEntity]
}
nonisolated struct RoutineListQuery: Equatable, Sendable {
    enum Sort: String, Sendable { case latest, likes, participants }
    var sort: Sort = .latest
    var authorID: String? = nil
    var cursor: String? = nil
    var size: Int = 20
}
