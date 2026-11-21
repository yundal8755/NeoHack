import Alamofire

nonisolated enum RoutineCommentEndpoint {
    static func list(routineID: String, headers: [String: String]) throws -> APIEndpoint {
        APIEndpoint(method: .get, path: "api/routines/\(try Mapping.pathID(routineID))/comments", headers: headers)
    }
    static func save(routineID: String, commentID: String? = nil, content: String, headers: [String: String]) throws
        -> APIEndpoint
    {
        guard content.count <= 50 else { throw DataContractError.invalidValue("content") }
        let suffix = try commentID.map { "/\(try Mapping.pathID($0))" } ?? ""
        return try APIEndpoint(
            method: commentID == nil ? .post : .patch,
            path: "api/routines/\(try Mapping.pathID(routineID))/comments\(suffix)", headers: headers,
            body: RoutineCommentRequestDTO(content: content))
    }
    static func delete(routineID: String, commentID: String, headers: [String: String]) throws -> APIEndpoint {
        APIEndpoint(
            method: .delete,
            path: "api/routines/\(try Mapping.pathID(routineID))/comments/\(try Mapping.pathID(commentID))",
            headers: headers)
    }
}
