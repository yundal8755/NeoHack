import Foundation

nonisolated protocol RoutineRepository {
    func list(query: RoutineListQuery) async throws -> RoutinePageEntity
    func detail(id: String) async throws -> RoutineDetailEntity
    func create(input: RoutineSaveInput) async throws -> RoutineDetailEntity
    func update(id: String, input: RoutineSaveInput) async throws -> RoutineDetailEntity
    func delete(id: String) async throws
}
