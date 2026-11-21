import Foundation

nonisolated struct RoutineCardEntity: Equatable, Sendable {
    var id: String? = nil
    var order: Int? = nil
    var imageURL: URL? = nil
    let imageID: String
    let title: String
    let content: String?
    let time: String
}
