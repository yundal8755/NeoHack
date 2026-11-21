nonisolated protocol HealthRepository {
    func status() async throws -> String
}
