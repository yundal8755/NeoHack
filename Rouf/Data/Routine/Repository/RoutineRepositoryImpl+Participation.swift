extension RoutineRepositoryImpl {
    func participationDraft(routineID: String) async throws -> RoutineParticipationDraft? {
        let response = try await network.request(
            RoutineParticipationEndpoint.draft(routineID: routineID, headers: headers()),
            as: APIResponseDTO<RoutineParticipationDraftDTO>.self)
        try response.checkSuccess()
        return response.result.map(RoutineParticipationMapper.draft)
    }

    func saveParticipationDraft(routineID: String, draft: RoutineParticipationDraft) async throws
        -> RoutineParticipationDraft
    {
        let response = try await network.request(
            RoutineParticipationEndpoint.saveDraft(routineID: routineID, draft: draft, headers: headers()),
            as: APIResponseDTO<RoutineParticipationDraftDTO>.self)
        return try RoutineParticipationMapper.draft(response.value())
    }

    func completeParticipation(id: String, input: RoutineSaveInput) async throws -> RoutineInteractions {
        let response = try await network.request(
            RoutineParticipationEndpoint.complete(routineID: id, input: input, headers: headers()),
            as: APIResponseDTO<RoutineInteractionsResponseDTO>.self)
        return try RoutineMapper.interactions(response.value())
    }

    func participationResults(routineID: String) async throws -> RoutineParticipationResults {
        let response = try await network.request(
            RoutineParticipationEndpoint.results(routineID: routineID),
            as: APIResponseDTO<RoutineParticipationResultsDTO>.self)
        return try RoutineParticipationMapper.results(response.value())
    }

    func participationResult(routineID: String, participantID: String) async throws -> RoutineParticipationResult {
        let response = try await network.request(
            RoutineParticipationEndpoint.result(routineID: routineID, participantID: participantID),
            as: APIResponseDTO<RoutineParticipationResultDTO>.self)
        return try RoutineParticipationMapper.result(response.value())
    }

    func updateParticipationResult(
        routineID: String, participantID: String, input: RoutineSaveInput
    ) async throws -> RoutineParticipationResult {
        let response = try await network.request(
            RoutineParticipationEndpoint.updateResult(
                routineID: routineID, participantID: participantID, input: input, headers: headers()),
            as: APIResponseDTO<RoutineParticipationResultDTO>.self)
        return try RoutineParticipationMapper.result(response.value())
    }

    func deleteParticipationResult(routineID: String, participantID: String) async throws {
        let response = try await network.request(
            RoutineParticipationEndpoint.deleteResult(
                routineID: routineID, participantID: participantID, headers: headers()),
            as: APIDeleteResponseDTO.self)
        try response.checkSuccess()
    }
}
