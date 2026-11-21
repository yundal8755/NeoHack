import Alamofire
import Foundation
import Testing

@testable import HackertonBoilerplate

@MainActor
@Suite(.serialized)
struct DataDomainTests {
    private let id = "01KB0000000000000000DEF001"
    private let token = "test-device-token"

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try CodableManager.shared.responseDecoder.decode(type, from: Data(json.utf8))
    }

    @Test func dtoAndMapper() throws {
        let user = try decode(UserResponseDTO.self, #"{"publicId":"user","nickname":"닉네임"}"#)
        #expect(try UserMapper.map(user) == UserEntity(id: "user", nickname: "닉네임", profileImageID: nil))
        #expect(throws: DataContractError.missingField("publicId")) {
            try UserMapper.map(decode(UserResponseDTO.self, #"{"nickname":"닉네임"}"#))
        }
        #expect(throws: DataContractError.missingField("nickname")) {
            try UserMapper.map(decode(UserResponseDTO.self, #"{"publicId":"user"}"#))
        }
        let comment = try decode(
            RoutineCommentResponseDTO.self,
            #"{"commentId":"comment","content":"댓글","isMine":false,"createdAt":"2026-11-21T15:00:00.123Z"}"#)
        let entity = try RoutineCommentMapper.map(comment)
        #expect(entity.id == "comment")
        #expect(entity.isMine == false)
        #expect(entity.createdAt != nil)
        let detail = try decode(
            RoutineDetailResponseDTO.self,
            #"{"routineId":"routine","title":"루틴 제목","cards":[{"imageId":"image","title":"카드 제목","time":"07:30"}],"owner":{"userId":"user"},"createdAt":"2026-11-21T15:00:00Z"}"#
        )
        let routine = try RoutineMapper.detail(detail)
        #expect(routine.cards?.first?.time == "07:30")
        #expect(routine.owner?.nickname == nil)
        #expect(routine.likeCount == nil)
        let page = try decode(
            RoutinePageResponseDTO.self,
            #"{"routines":[{"routineId":"routine","title":"루틴 제목","thumbnailUrl":"https://example.com/image","likeCount":9223372036854775807}],"size":20,"hasNext":false,"nextCursor":null}"#
        )
        let mappedPage = try RoutineMapper.page(page)
        #expect(mappedPage.routines?.first?.likeCount == Int64.max)
        #expect(mappedPage.nextCursor == nil)
        #expect(
            try RoutineMapper.page(
                decode(RoutinePageResponseDTO.self, #"{"routines":[],"hasNext":true,"nextCursor":"next"}"#)
            ).nextCursor == "next")
        let image = try decode(
            ImageUploadResponseDTO.self,
            #"{"imageId":"image","imageUrl":"https://example.com/image","byteSize":42,"width":100,"height":200}"#)
        #expect(try ImageMapper.map(image).imageURL?.host == "example.com")
        #expect(try ImageMapper.map(image).byteSize == 42)
    }

    @Test(arguments: ["bad", "2026-99-99T00:00:00Z", ""])
    func invalidDate(value: String) {
        #expect(throws: DataContractError.invalidValue("date")) { try Mapping.date(value, "date") }
    }

    @Test(arguments: ["invalid", "file:///tmp/image", "ftp://example.com/image", ""])
    func invalidURL(value: String) {
        #expect(throws: DataContractError.invalidValue("url")) { try Mapping.url(value, "url") }
    }

    @Test func envelopes() throws {
        #expect(throws: NetworkError.apiError(code: "DENIED", message: "거절")) {
            try decode(APIResponseDTO<UserResponseDTO>.self, #"{"isSuccess":false,"code":"DENIED","message":"거절"}"#)
                .value()
        }
        #expect(throws: DataContractError.missingField("result")) {
            try decode(APIResponseDTO<UserResponseDTO>.self, #"{"isSuccess":true}"#).value()
        }
        #expect(throws: DataContractError.missingField("isSuccess")) {
            try decode(APIDeleteResponseDTO.self, "{}").checkSuccess()
        }
        for json in [
            #"{"isSuccess":true}"#, #"{"isSuccess":true,"result":null}"#,
            #"{"isSuccess":true,"result":{"unknown":[1,2]}}"#,
        ] {
            try decode(APIDeleteResponseDTO.self, json).checkSuccess()
        }
        #expect(throws: (any Error).self) { try decode(RoutineCardResponseDTO.self, #"{"title":"제목"}"#) }
    }

    private var input: RoutineSaveInput {
        RoutineSaveInput(
            title: "나의 아침 루틴", content: nil,
            cards: [RoutineCardEntity(imageID: id, title: "기상 후 물 마시기", content: nil, time: "07:30")])
    }

    @Test func endpoints() throws {
        let headers = try Mapping.deviceHeaders { token }
        let cases: [(APIEndpoint, String, String, Bool)] = [
            (UserEndpoint.list(headers: headers), "GET", "/api/users", true),
            (try UserEndpoint.create(nickname: "닉네임", headers: headers), "POST", "/api/users", true),
            (UserEndpoint.me(headers: headers), "GET", "/api/users/me", true),
            (try RoutineEndpoint.list(query: .init()), "GET", "/api/routines", false),
            (try RoutineEndpoint.detail(id: id), "GET", "/api/routines/\(id)", false),
            (try RoutineEndpoint.save(input: input, headers: headers), "POST", "/api/routines", true),
            (try RoutineEndpoint.save(id: id, input: input, headers: headers), "PUT", "/api/routines/\(id)", true),
            (try RoutineEndpoint.delete(id: id, headers: headers), "DELETE", "/api/routines/\(id)", true),
            (
                try RoutineCommentEndpoint.list(routineID: id, headers: headers), "GET", "/api/routines/\(id)/comments",
                true
            ),
            (
                try RoutineCommentEndpoint.save(routineID: id, content: "댓글", headers: headers), "POST",
                "/api/routines/\(id)/comments", true
            ),
            (
                try RoutineCommentEndpoint.save(routineID: id, commentID: id, content: "수정", headers: headers), "PATCH",
                "/api/routines/\(id)/comments/\(id)", true
            ),
            (
                try RoutineCommentEndpoint.delete(routineID: id, commentID: id, headers: headers), "DELETE",
                "/api/routines/\(id)/comments/\(id)", true
            ),
            (ImageEndpoint.upload(headers: headers), "POST", "/api/images", true),
            (try ImageEndpoint.data(id: id), "GET", "/api/images/\(id)", false),
        ]
        for (target, method, path, authenticated) in cases {
            let request = try target.asURLRequest()
            #expect(request.httpMethod == method)
            #expect(request.url?.path == path)
            #expect(request.value(forHTTPHeaderField: "X-Device-Token") == (authenticated ? token : nil))
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        }
        let query = RoutineListQuery(sort: .likes, authorID: id, cursor: "a+b/=", size: 50)
        let request = try RoutineEndpoint.list(query: query).asURLRequest()
        let items = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
        let values = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
        #expect(values == ["sort": "likes", "authorId": id, "cursor": "a+b/=", "size": "50"])
        let save = try RoutineEndpoint.save(input: input, headers: headers).asURLRequest()
        let saveBody = try #require(save.httpBody)
        let object = try JSONSerialization.jsonObject(with: saveBody)
        let json = try #require(object as? [String: Any])
        #expect(json["title"] as? String == input.title)
        #expect((json["cards"] as? [[String: Any]])?.first?["imageId"] as? String == id)
        let userBody = try UserEndpoint.create(nickname: "닉네임", headers: headers).asURLRequest().httpBody
        #expect(try JSONSerialization.jsonObject(with: #require(userBody)) as? [String: String] == ["nickname": "닉네임"])
        let commentBody = try RoutineCommentEndpoint.save(routineID: id, content: "댓글", headers: headers).asURLRequest()
            .httpBody
        #expect(try JSONSerialization.jsonObject(with: #require(commentBody)) as? [String: String] == ["content": "댓글"])
    }

    @Test func validation() throws {
        for value in ["", "  ", "bad\r\nheader", String(repeating: "x", count: 256)] {
            #expect(throws: DataContractError.missingDeviceToken) { try Mapping.deviceHeaders { value } }
        }
        #expect(throws: (any Error).self) { try RoutineEndpoint.detail(id: "../users") }
        #expect(throws: (any Error).self) { try RoutineEndpoint.list(query: .init(size: 0)) }
        #expect(throws: (any Error).self) { try RoutineEndpoint.list(query: .init(size: 51)) }
        #expect(throws: (any Error).self) {
            try RoutineEndpoint.save(input: .init(title: "짧음", content: nil, cards: []), headers: [:])
        }
        #expect(throws: (any Error).self) {
            try UserEndpoint.create(nickname: String(repeating: "가", count: 31), headers: [:])
        }
        #expect(throws: (any Error).self) {
            try RoutineCommentEndpoint.save(routineID: id, content: String(repeating: "가", count: 51), headers: [:])
        }
        #expect(throws: (any Error).self) {
            try RoutineEndpoint.save(
                input: .init(
                    title: input.title, content: nil,
                    cards: [.init(imageID: id, title: "올바른 제목", content: nil, time: "24:00")]), headers: [:])
        }
        // 명세의 minItems/minLength=0을 유지한다. 설명과의 충돌은 API 문서에 기록한다.
        _ = try RoutineEndpoint.save(input: .init(title: input.title, content: nil, cards: []), headers: [:])
        _ = try RoutineCommentEndpoint.save(routineID: id, content: "", headers: [:])
    }

    private func network(_ handler: @escaping (URLRequest) throws -> (Int, Data)) -> NetworkManager {
        StubURLProtocol.setHandler(handler)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return NetworkManager(session: Session(configuration: configuration))
    }

    @Test func repositories() async throws {
        let network = network { request in
            let path = request.url!.path
            let method = request.httpMethod!
            if method == "DELETE" { return (200, Data(#"{"isSuccess":true,"result":{}}"#.utf8)) }
            if path.hasPrefix("/api/images/") { return (200, Data([1, 2, 3])) }
            if !(path.hasPrefix("/api/routines") && method == "GET" && !path.contains("comments")) {
                #expect(request.value(forHTTPHeaderField: "X-Device-Token") == token)
            }
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            let result: String
            if path == "/api/images" {
                #expect(
                    request.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data; boundary=")
                        == true)
                var data = request.httpBody ?? Data()
                if let stream = request.httpBodyStream {
                    stream.open()
                    defer { stream.close() }
                    var buffer = [UInt8](repeating: 0, count: 1024)
                    while stream.hasBytesAvailable {
                        let count = stream.read(&buffer, maxLength: buffer.count)
                        if count <= 0 { break }
                        data.append(contentsOf: buffer.prefix(count))
                    }
                }
                let multipart = String(decoding: data, as: UTF8.self)
                #expect(multipart.contains("name=\"file\"; filename=\"test.jpg\""))
                #expect(multipart.contains("Content-Type: image/jpeg"))
                #expect(multipart.contains("image-bytes"))
                result = #"{"imageId":"image","imageUrl":"https://example.com/image"}"#
            } else if path.contains("comments") {
                let comment = #"{"commentId":"comment","content":"댓글"}"#
                result = method == "GET" ? "[\(comment)]" : comment
            } else if path.hasPrefix("/api/users") {
                let user = #"{"publicId":"user","nickname":"닉네임"}"#
                result = path == "/api/users" && method == "GET" ? "[\(user)]" : user
            } else if path == "/api/routines" && method == "GET" {
                result = #"{"routines":[],"hasNext":false}"#
            } else {
                result = #"{"routineId":"routine","title":"루틴 제목"}"#
            }
            return (200, Data("{\"isSuccess\":true,\"result\":\(result)}".utf8))
        }
        let user: any UserRepository = UserRepositoryImpl(networkManager: network, deviceToken: { token })
        #expect(try await user.list().count == 1)
        #expect(try await user.create(nickname: "닉네임").id == "user")
        #expect(try await user.me().nickname == "닉네임")
        let routine: any RoutineRepository = RoutineRepositoryImpl(networkManager: network, deviceToken: { token })
        #expect(try await routine.list(query: .init()).routines == [])
        #expect(try await routine.detail(id: id).id == "routine")
        #expect(try await routine.create(input: input).title == "루틴 제목")
        #expect(try await routine.update(id: id, input: input).id == "routine")
        try await routine.delete(id: id)
        let comment: any RoutineCommentRepository = RoutineCommentRepositoryImpl(
            networkManager: network, deviceToken: { token })
        #expect(try await comment.list(routineID: id).count == 1)
        #expect(try await comment.create(routineID: id, content: "댓글").id == "comment")
        #expect(try await comment.update(routineID: id, commentID: id, content: "댓글").content == "댓글")
        try await comment.delete(routineID: id, commentID: id)
        let image: any ImageRepository = ImageRepositoryImpl(networkManager: network, deviceToken: { token })
        #expect(
            try await image.upload(
                input: .init(data: Data("image-bytes".utf8), fileName: "test.jpg", mimeType: "image/jpeg")
            ).id == "image")
        #expect(try await image.data(id: id) == Data([1, 2, 3]))
    }

    @Test func repositoryFailures() async throws {
        var manager = network { _ in (403, Data(#"{"code":"DENIED","message":"거절"}"#.utf8)) }
        var repo = UserRepositoryImpl(networkManager: manager, deviceToken: { token })
        await #expect(throws: NetworkError.apiError(code: "DENIED", message: "거절")) { try await repo.me() }
        manager = network { _ in (200, Data(#"{"isSuccess":false,"code":"FAILED","message":"실패"}"#.utf8)) }
        repo = UserRepositoryImpl(networkManager: manager, deviceToken: { token })
        await #expect(throws: NetworkError.apiError(code: "FAILED", message: "실패")) { try await repo.me() }
        manager = network { _ in (200, Data(#"{"isSuccess":true,"result":{"nickname":"이름"}}"#.utf8)) }
        repo = UserRepositoryImpl(networkManager: manager, deviceToken: { token })
        await #expect(throws: DataContractError.missingField("publicId")) { try await repo.me() }
        manager = network { _ in
            Issue.record("빈 토큰으로 요청하면 안 됩니다.")
            return (500, Data())
        }
        repo = UserRepositoryImpl(networkManager: manager, deviceToken: { "" })
        await #expect(throws: DataContractError.missingDeviceToken) { try await repo.me() }
        let image = ImageRepositoryImpl(networkManager: manager, deviceToken: { token })
        await #expect(throws: DataContractError.invalidValue("file")) {
            try await image.upload(input: .init(data: Data(), fileName: "image.jpg", mimeType: "image/jpeg"))
        }
        for (fileName, mimeType) in [("bad\r\nname", "image/jpeg"), ("bad\0name", "image/jpeg"), ("image.jpg", "image/jpeg;invalid")] {
            await #expect(throws: DataContractError.invalidValue("file")) {
                try await image.upload(input: .init(data: Data([1]), fileName: fileName, mimeType: mimeType))
            }
        }

    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var handler: ((URLRequest) throws -> (Int, Data))?
    static func setHandler(_ value: @escaping (URLRequest) throws -> (Int, Data)) {
        lock.lock()
        defer { lock.unlock() }
        handler = value
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        let handler = Self.handler
        Self.lock.unlock()
        do {
            let respond = try #require(handler)
            let (status, data) = try respond(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}
