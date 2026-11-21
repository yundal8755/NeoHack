import Alamofire

nonisolated enum TestAccountEndpoint {
    static let list = APIEndpoint(method: .get, path: "api/test-accounts")

    static func claim(accountID: String) throws -> APIEndpoint {
        APIEndpoint(method: .post, path: "api/test-accounts/\(try Mapping.pathID(accountID))/claim")
    }

    static func heartbeat(_ lease: TestAccountLease) throws -> APIEndpoint {
        APIEndpoint(method: .post, path: "api/test-accounts/\(try Mapping.pathID(lease.accountID))/heartbeat",
                    headers: try Mapping.bearerHeaders { lease.accessToken })
    }

    static func release(_ lease: TestAccountLease) throws -> APIEndpoint {
        APIEndpoint(method: .delete, path: "api/test-accounts/\(try Mapping.pathID(lease.accountID))/claim",
                    headers: try Mapping.bearerHeaders { lease.accessToken })
    }
}
