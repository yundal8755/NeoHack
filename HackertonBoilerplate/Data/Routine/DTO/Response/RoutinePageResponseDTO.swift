import Foundation

nonisolated struct RoutinePageResponseDTO: Decodable, Equatable, Sendable {
    let routines: [RoutineSummaryResponseDTO]?
    let size: Int?
    let hasNext: Bool?
    let nextCursor: String?
    var totalCount: Int? = nil
}
