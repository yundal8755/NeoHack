import Foundation

nonisolated struct RoutineSaveRequestDTO: Encodable, Equatable, Sendable {
    let title: String
    let content: String?
    let cards: [RoutineCardRequestDTO]
}
