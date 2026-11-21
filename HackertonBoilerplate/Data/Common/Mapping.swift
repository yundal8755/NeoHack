import Foundation

nonisolated enum DataContractError: Error, Equatable {
    case missingField(String)
    case invalidValue(String)
    case missingDeviceToken
}

nonisolated enum Mapping {
    static func required<T>(_ value: T?, _ field: String) throws -> T {
        guard let value else { throw DataContractError.missingField(field) }
        return value
    }
    static func identity(_ value: String?, _ field: String) throws -> String {
        let value = try required(value, field)
        guard !value.isEmpty else { throw DataContractError.invalidValue(field) }
        return value
    }
    static func url(_ value: String?, _ field: String) throws -> URL? {
        guard let value else { return nil }
        guard let url = ServerAPI.httpURL(from: value) else { throw DataContractError.invalidValue(field) }
        return url
    }
    static func date(_ value: String?, _ field: String) throws -> Date? {
        guard let value else { return nil }
        // The server also returns Seoul local timestamps without a zone.
        let localPattern = #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?$"#
        let timestamp = value.range(of: localPattern, options: .regularExpression) == nil ? value : value + "+09:00"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: timestamp) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: timestamp) else { throw DataContractError.invalidValue(field) }
        return date
    }
    static func pathID(_ value: String) throws -> String {
        guard value.range(of: "^[0-9A-HJKMNP-TV-Z]{26}$", options: .regularExpression) != nil else {
            throw DataContractError.invalidValue("id")
        }
        return value
    }
    static func deviceHeaders(_ token: () throws -> String, userID: String? = nil) throws -> [String: String] {
        let value = try token()
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            value.count <= 255,
            !value.contains(where: { $0.isNewline || $0.asciiValue.map { $0 < 32 || $0 == 127 } == true })
        else {
            throw DataContractError.missingDeviceToken
        }
        var headers = ["X-Device-Token": value]
        if let userID { headers["X-User-Id"] = try pathID(userID) }
        return headers
    }
}
