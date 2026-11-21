import Foundation
import HackertonCore
import Testing

@Suite("Example DTO")
struct ExampleDTOTests {
    @Test func 요청을_명세의_name_키로_인코딩한다() throws {
        let data = try JSONEncoder().encode(ExampleCreateRequestDTO(name: "예제"))
        let fields = try JSONDecoder().decode([String: String].self, from: data)

        #expect(fields == ["name": "예제"])
    }

    @Test func 응답의_필드와_Int64_ID를_디코딩한다() throws {
        let json = #"{"isSuccess":true,"code":"COMMON200","message":"성공","result":{"id":9223372036854775807,"name":"예제"}}"#
        let response = try responseDecoder.decode(ExampleAPIResponseDTO.self, from: Data(json.utf8))

        #expect(response.isSuccess == true)
        #expect(response.code == "COMMON200")
        #expect(response.message == "성공")
        #expect(response.result?.id == Int64.max)
        #expect(response.result?.name == "예제")
    }

    @Test(arguments: [
        #"{}"#,
        #"{"isSuccess":null,"code":null,"message":null,"result":null}"#,
    ])
    func 선택_필드가_없거나_null이면_nil이다(json: String) throws {
        let response = try responseDecoder.decode(ExampleAPIResponseDTO.self, from: Data(json.utf8))

        #expect(response.isSuccess == nil)
        #expect(response.code == nil)
        #expect(response.message == nil)
        #expect(response.result == nil)
    }

    @Test(arguments: [#"{}"#, #"{"id":null,"name":null}"#])
    func 예제_응답의_선택_필드도_누락과_null을_허용한다(json: String) throws {
        let response = try responseDecoder.decode(ExampleResponseDTO.self, from: Data(json.utf8))

        #expect(response.id == nil)
        #expect(response.name == nil)
    }

    @Test(arguments: [
        #"{"isSuccess":"true"}"#,
        #"{"code":200}"#,
        #"{"message":[]}"#,
        #"{"result":"example"}"#,
        #"{"result":{"id":"1"}}"#,
        #"{"result":{"name":false}}"#,
        #"{"result":{"id":9223372036854775808}}"#,
    ])
    func 잘못된_필드_타입이나_ID_범위는_오류로_전달한다(json: String) {
        #expect(throws: DecodingError.self) {
            try responseDecoder.decode(ExampleAPIResponseDTO.self, from: Data(json.utf8))
        }
    }

    private var responseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
