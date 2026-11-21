import Foundation

nonisolated struct RoutineCardRequestDTO: Encodable, Equatable, Sendable {
    let imageId: String
    let title: String
    let content: String?
    let time: String
}
