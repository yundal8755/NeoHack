import Foundation

nonisolated struct APIResponseDTO<Result: Decodable>: Decodable {
    let isSuccess: Bool?
    let code: String?
    let message: String?
    let result: Result?

    func value() throws -> Result {
        try checkSuccess()
        return try Mapping.required(result, "result")
    }
    func checkSuccess() throws {
        guard let isSuccess else { throw DataContractError.missingField("isSuccess") }
        guard isSuccess else {
            throw NetworkError.apiError(code: code ?? "SERVER_ERROR", message: message ?? "요청에 실패했습니다.")
        }
    }
}
// result의 스키마가 미정인 삭제 응답은 메타데이터만 디코딩한다.
nonisolated struct APIDeleteResponseDTO: Decodable {
    let isSuccess: Bool?
    let code: String?
    let message: String?
    func checkSuccess() throws {
        try APIResponseDTO<String>(isSuccess: isSuccess, code: code, message: message, result: nil).checkSuccess()
    }
}
