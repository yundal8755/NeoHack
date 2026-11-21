import Foundation

nonisolated struct RoutineCardResponseDTO: Decodable, Equatable, Sendable {
    let imageId: String
    let title: String
    let content: String?
    let time: String
}
