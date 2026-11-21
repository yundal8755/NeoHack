import Alamofire

nonisolated enum RoutineParticipationEndpoint {
    static func draft(routineID: String, headers: [String: String]) throws -> APIEndpoint {
        APIEndpoint(
            method: .get, path: "api/routines/\(try Mapping.pathID(routineID))/participation/draft", headers: headers)
    }

    static func saveDraft(
        routineID: String, draft: RoutineParticipationDraft, headers: [String: String]
    ) throws -> APIEndpoint {
        try APIEndpoint(
            method: .put, path: "api/routines/\(Mapping.pathID(routineID))/participation/draft",
            headers: headers, body: RoutineParticipationMapper.request(draft))
    }

    static func complete(routineID: String, input: RoutineSaveInput, headers: [String: String]) throws -> APIEndpoint {
        try RoutineEndpoint.saveRequest(
            method: .put, path: "api/routines/\(Mapping.pathID(routineID))/participation/completion",
            input: input, headers: headers)
    }

    static func results(routineID: String) throws -> APIEndpoint {
        APIEndpoint(method: .get, path: try resultsPath(routineID: routineID))
    }

    static func result(routineID: String, participantID: String) throws -> APIEndpoint {
        APIEndpoint(method: .get, path: try resultsPath(routineID: routineID, participantID: participantID))
    }

    static func updateResult(
        routineID: String, participantID: String, input: RoutineSaveInput, headers: [String: String]
    ) throws -> APIEndpoint {
        try RoutineEndpoint.saveRequest(
            method: .put, path: resultsPath(routineID: routineID, participantID: participantID),
            input: input, headers: headers)
    }

    static func deleteResult(routineID: String, participantID: String, headers: [String: String]) throws -> APIEndpoint
    {
        APIEndpoint(
            method: .delete, path: try resultsPath(routineID: routineID, participantID: participantID), headers: headers
        )
    }

    private static func resultsPath(routineID: String, participantID: String? = nil) throws -> String {
        let base = "api/routines/\(try Mapping.pathID(routineID))/participation-results"
        guard let participantID else { return base }
        return "\(base)/\(try Mapping.pathID(participantID))"
    }
}
