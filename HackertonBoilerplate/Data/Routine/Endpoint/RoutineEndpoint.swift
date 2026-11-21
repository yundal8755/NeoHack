import Alamofire
import Foundation

nonisolated enum RoutineEndpoint {
    static func list(query: RoutineListQuery, headers: [String: String] = [:]) throws -> APIEndpoint {
        guard (1...50).contains(query.size) else { throw DataContractError.invalidValue("size") }
        var parameters: Parameters = ["sort": query.sort.rawValue, "size": query.size]
        if let authorID = query.authorID { parameters["authorId"] = try Mapping.pathID(authorID) }
        if let participantID = query.participantID { parameters["participantId"] = try Mapping.pathID(participantID) }
        if let cursor = query.cursor { parameters["cursor"] = cursor }
        return APIEndpoint(method: .get, path: "api/routines", headers: headers, parameters: parameters)
    }
    static func detail(id: String) throws -> APIEndpoint {
        APIEndpoint(method: .get, path: "api/routines/\(try Mapping.pathID(id))")
    }
    static func save(id: String? = nil, input: RoutineSaveInput, headers: [String: String]) throws -> APIEndpoint {
        let path = try id.map { "api/routines/\(try Mapping.pathID($0))" } ?? "api/routines"
        guard (5...30).contains(input.title.count), (input.content?.count ?? 0) <= 500,
            input.cards.count <= 10
        else { throw DataContractError.invalidValue("routine") }
        for card in input.cards {
            _ = try Mapping.pathID(card.imageID)
            guard (5...30).contains(card.title.count), (card.content?.count ?? 0) <= 100,
                card.time.range(of: "^([01][0-9]|2[0-3]):[0-5][0-9]$", options: .regularExpression) != nil
            else {
                throw DataContractError.invalidValue("card")
            }
        }
        return try APIEndpoint(
            method: id == nil ? .post : .put, path: path, headers: headers, body: RoutineMapper.request(input))
    }
    static func interactions(
        id: String, change: RoutineInteractions.Change?, headers: [String: String]
    ) throws -> APIEndpoint {
        let route: (HTTPMethod, String) = switch change {
        case nil: (.get, "interactions")
        case .like: (.put, "like")
        case .unlike: (.delete, "like")
        case .join: (.put, "participation")
        case .leave: (.delete, "participation")
        case .complete: (.put, "participation/completion")
        }
        return APIEndpoint(method: route.0, path: "api/routines/\(try Mapping.pathID(id))/\(route.1)", headers: headers)
    }
    static func completeParticipation(id: String, input: RoutineSaveInput, headers: [String: String]) throws -> APIEndpoint {
        _ = try save(input: input, headers: headers)
        return try APIEndpoint(method: .put, path: "api/routines/\(Mapping.pathID(id))/participation/completion",
                               headers: headers, body: RoutineMapper.request(input))
    }
    static func participationResult(id: String, participantID: String) throws -> APIEndpoint {
        try APIEndpoint(method: .get,
                        path: "api/routines/\(Mapping.pathID(id))/participation-results/\(Mapping.pathID(participantID))")
    }
    static func delete(id: String, headers: [String: String]) throws -> APIEndpoint {
        APIEndpoint(method: .delete, path: "api/routines/\(try Mapping.pathID(id))", headers: headers)
    }
}
