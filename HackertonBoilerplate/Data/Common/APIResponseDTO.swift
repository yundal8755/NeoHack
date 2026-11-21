import Foundation

nonisolated struct APIResponseDTO<Result: Decodable>: Decodable {
    let result: Result?
    let fieldErrors: [String: String]?
    private let status: APIDeleteResponseDTO

    private enum CodingKeys: String, CodingKey { case result }

    init(from decoder: Decoder) throws {
        status = try APIDeleteResponseDTO(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if status.isSuccess == false {
            result = nil
            fieldErrors = try? container.decode([String: String].self, forKey: .result)
        } else {
            result = try container.decodeIfPresent(Result.self, forKey: .result)
            fieldErrors = nil
        }
    }

    func value() throws -> Result {
        try checkSuccess()
        return try Mapping.required(result, "result")
    }

    func checkSuccess() throws {
        try status.checkSuccess()
    }
}

// result의 스키마가 미정인 삭제 응답은 메타데이터만 디코딩한다.
nonisolated struct APIDeleteResponseDTO: Decodable {
    let isSuccess: Bool?
    let code: String?
    let message: String?

    func checkSuccess() throws {
        guard let isSuccess else { throw DataContractError.missingField("isSuccess") }
        guard isSuccess else {
            throw NetworkError.apiError(code: code ?? "SERVER_ERROR", message: message ?? "요청에 실패했습니다.")
        }
    }
}
