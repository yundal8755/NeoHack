import Foundation

nonisolated struct RoutinePageEntity: Equatable, Sendable {
    let routines: [RoutineSummaryEntity]?
    let size: Int?
    let hasNext: Bool?
    let nextCursor: String?
    var totalCount: Int? = nil
}
