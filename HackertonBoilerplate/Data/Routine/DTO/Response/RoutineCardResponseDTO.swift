import Foundation

nonisolated struct RoutineCardResponseDTO: Decodable, Equatable, Sendable {
    let cardId: String?
    let order: Int?
    let imageUrl: String?
    let imageId: String?
    let title: String?
    let content: String?
    let time: String?
}
