import Foundation

nonisolated struct RoutineCardEntity: Equatable, Sendable {
    let imageID: String
    let title: String
    let content: String?
    let time: String
}
