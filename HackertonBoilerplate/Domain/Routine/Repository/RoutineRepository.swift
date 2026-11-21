import Foundation

nonisolated protocol RoutineRepository {
    func list(query: RoutineListQuery) async throws -> RoutinePageEntity
    func detail(id: String) async throws -> RoutineDetailEntity
    func create(input: RoutineSaveInput) async throws -> RoutineDetailEntity
    func update(id: String, input: RoutineSaveInput) async throws -> RoutineDetailEntity
    func interactions(id: String, change: RoutineInteractions.Change?) async throws -> RoutineInteractions
    func participationDraft(routineID: String) async throws -> RoutineParticipationDraft?
    func saveParticipationDraft(routineID: String, draft: RoutineParticipationDraft) async throws
        -> RoutineParticipationDraft
    func completeParticipation(id: String, input: RoutineSaveInput) async throws -> RoutineInteractions
    func participationResults(routineID: String) async throws -> RoutineParticipationResults
    func participationResult(id: String, participantID: String) async throws -> RoutineDetailEntity
    func participationResult(routineID: String, participantID: String) async throws -> RoutineParticipationResult
    func updateParticipationResult(routineID: String, participantID: String, input: RoutineSaveInput) async throws
        -> RoutineParticipationResult
    func deleteParticipationResult(routineID: String, participantID: String) async throws
    func delete(id: String) async throws
}
