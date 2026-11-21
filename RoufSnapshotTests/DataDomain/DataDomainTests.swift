import Alamofire
import Foundation
import RoufCore
import MVICore
import Testing

@testable import Rouf

@MainActor
@Suite(.serialized)
struct DataDomainTests {
    private let id = "01KB0000000000000000DEF001"
    private let token = "test-device-token"

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try CodableManager.shared.responseDecoder.decode(type, from: Data(json.utf8))
    }

    @Test func liveContractFields() throws {
        let local = try Mapping.date("2026-11-22T00:45:42.72887", "createdAt")
        let utc = try Mapping.date("2026-11-21T15:45:42.72887Z", "createdAt")
        #expect(local == utc)
        let response = try decode(RoutineDetailResponseDTO.self, """
            {"routineId":"routine","title":"루틴 제목","cards":[
              {"cardId":"later","order":2,"imageId":"image","title":"두 번째","time":"09:00"},
              {"cardId":"first","order":1,"imageId":"image","title":"첫 번째","time":"08:00","imageUrl":"https://example.com/card"}
            ]}
            """)
        let detail = try RoutineMapper.detail(response)
        #expect(detail.cards?.map(\.id) == ["first", "later"])
        #expect(detail.cards?.first?.imageURL?.path == "/card")
    }

    @Test func selectedProfileAndInteractionRoutes() async throws {
        let expected = [
            "/interactions": "GET", "/participation/completion": "PUT",
        ]
        let manager = network { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
            #expect(request.value(forHTTPHeaderField: "X-User-Id") == nil)
            let path = request.url?.path ?? ""
            if path == "/api/users/me" {
                return (
                    200,
                    Data(
                        """
                        {"isSuccess":true,"result":{"publicId":"\(id)","nickname":"프로필","bio":"한 줄"}}
                        """.utf8)
                )
            }
            for (suffix, method) in expected where path.hasSuffix(suffix) {
                #expect(request.httpMethod == method)
            }
            return (
                200,
                Data(
                    #"{"isSuccess":true,"result":{"likeCount":1,"likedByMe":true,"inProgressCount":2,"completedCount":3,"myParticipationStatus":"COMPLETED"}}"#
                        .utf8)
            )
        }
        let user = UserRepositoryImpl(networkManager: manager, accessToken: { token })
        #expect(try await user.me().id == id)
        let routines = RoutineRepositoryImpl(networkManager: manager, accessToken: { token })
        for (change, method, suffix) in [
            (nil, "GET", "/interactions"), (RoutineInteractions.Change.like, "PUT", "/like"),
            (.unlike, "DELETE", "/like"), (.join, "PUT", "/participation"),
            (.leave, "DELETE", "/participation"),
        ] {
            let request = try RoutineEndpoint.interactions(id: id, change: change, headers: [:]).asURLRequest()
            #expect(request.httpMethod == method)
            #expect(request.url?.path.hasSuffix(suffix) == true)
            #expect(try await routines.interactions(id: id, change: change).participation == .completed)
        }
        await #expect(throws: RoutineParticipationError.completionRequiresInput) {
            try await routines.interactions(id: id, change: .complete)
        }
        let completion = try RoutineParticipationEndpoint.complete(routineID: id, input: input, headers: [:])
            .asURLRequest()
        let body = try #require(completion.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect((json?["cards"] as? [[String: String]])?.first?["imageId"] == id)
        #expect(try await routines.completeParticipation(id: id, input: input).participation == .completed)
    }

    @Test func participationDraftAndResultContract() async throws {
        let base = "/api/routines/\(id)"
        let draft = #"{"title":"초안","cards":[null,{"time":"09:30"}]}"#
        let participant = #"{"userId":"user","nickname":"테스터"}"#
        let result = """
            {"routineId":"\(id)","participant":\(participant),"completedAt":"2026-11-22T09:30:00",
             "work":{"title":"완료 결과","cards":[{"imageId":"\(id)","title":"완료 스텝","time":"09:30"}]}}
            """
        let manager = network { request in
            let path = request.url?.path ?? ""
            let method = request.httpMethod ?? ""
            let authenticated = path.hasSuffix("/draft") || method != "GET"
            #expect(request.value(forHTTPHeaderField: "Authorization") == (authenticated ? "Bearer \(token)" : nil))
            let body: String
            switch (method, path) {
            case ("GET", "\(base)/participation/draft"): body = "null"
            case ("PUT", "\(base)/participation/draft"): body = draft
            case ("GET", "\(base)/participation-results"):
                body = """
                    {"totalCount":1,"results":[{"participant":\(participant),"title":"완료 결과","thumbnailUrl":"https://example.com/step"}]}
                    """
            case ("GET", "\(base)/participation-results/\(id)"), ("PUT", "\(base)/participation-results/\(id)"):
                body = result
            case ("DELETE", "\(base)/participation-results/\(id)"): body = "null"
            default: throw URLError(.unsupportedURL)
            }
            return (200, Data("{\"isSuccess\":true,\"result\":\(body)}".utf8))
        }

        let repo = RoutineRepositoryImpl(networkManager: manager, accessToken: { token })
        #expect(try await repo.participationDraft(routineID: id) == nil)
        let inputDraft = RoutineParticipationDraft(title: "초안", cards: [nil, .init(time: "09:30")])
        let request = try RoutineParticipationEndpoint.saveDraft(routineID: id, draft: inputDraft, headers: [:])
            .asURLRequest()
        let encoded = try decode(
            RoutineParticipationDraftDTO.self, String(decoding: #require(request.httpBody), as: UTF8.self))
        #expect(encoded.cards?.first == .some(nil))
        #expect(encoded.cards?.last??.time == "09:30")
        #expect(try await repo.saveParticipationDraft(routineID: id, draft: inputDraft) == inputDraft)
        let page = try await repo.participationResults(routineID: id)
        #expect(page.totalCount == 1)
        #expect(page.results?.first?.thumbnailURL?.path == "/step")
        let published = try await repo.participationResult(routineID: id, participantID: id)
        #expect(published.participant?.id == "user")
        #expect(published.work?.cards?.first??.imageID == id)
        let detail = try await repo.participationResult(id: id, participantID: id)
        #expect(detail.title == "완료 결과")
        #expect(detail.cards?.first?.imageURL?.path == "/api/images/\(id)")
        #expect(published.completedAt == (try Mapping.date("2026-11-22T00:30:00Z", "completedAt")))
        #expect(try await repo.updateParticipationResult(routineID: id, participantID: id, input: input) == published)
        try await repo.deleteParticipationResult(routineID: id, participantID: id)

        #expect(throws: DataContractError.invalidValue("time")) {
            try RoutineParticipationMapper.request(.init(cards: [.init(time: "24:00")]))
        }
    }

    @Test func publicProfileTestAccountAndHealthContract() async throws {
        let manager = network { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
            switch (request.httpMethod, request.url?.path) {
            case ("GET", "/api/users/\(id)"):
                return (
                    200,
                    Data(
                        """
                        {"isSuccess":true,"result":{"publicId":"\(id)","nickname":"테스터","bio":"한 줄","profileImagePublicId":"\(id)"}}
                        """.utf8)
                )
            case ("POST", "/api/test-accounts"):
                return (
                    201,
                    Data(
                        """
                        {"isSuccess":true,"result":{"publicId":"\(id)","slot":2,"nickname":"테스터","available":true,"profileImagePublicId":"\(id)"}}
                        """.utf8)
                )
            case ("GET", "/health"):
                #expect(request.value(forHTTPHeaderField: "Accept") == "text/plain")
                return (200, Data("OK".utf8))
            default:
                throw URLError(.unsupportedURL)
            }
        }

        let users = UserRepositoryImpl(networkManager: manager, accessToken: { token })
        let profile = try await users.profile(publicID: id)
        #expect(profile.bio == "한 줄")
        #expect(profile.profileImageURL?.path == "/api/images/\(id)")
        let input = TestAccountRegistration(slot: 2, nickname: "테스터", bio: "한 줄")
        let registerBody = try #require(TestAccountEndpoint.register(input).asURLRequest().httpBody)
        let encoded = try JSONSerialization.jsonObject(with: registerBody) as? [String: Any]
        #expect(encoded?["slot"] as? Int == 2)
        #expect(encoded?["bio"] as? String == "한 줄")
        let account = try await TestAccountRepositoryImpl(network: manager).register(input)
        #expect(account.profileImageID == id)
        #expect(try await HealthRepositoryImpl(network: manager).status() == "OK")
        #expect(throws: DataContractError.invalidValue("slot")) {
            try TestAccountEndpoint.register(.init(slot: 8, nickname: "테스터"))
        }
    }

    @Test func routineListMapsParticipationFields() async throws {
        let manager = network { request in
            let items = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems
            #expect(items?.first(where: { $0.name == "participantId" })?.value == id)
            let body = """
                {"isSuccess":true,"result":{"totalCount":5000000000,"routines":[
                  {"routineId":"routine","title":"루틴 제목","likedByMe":true,"inProgressCount":2,
                   "completedCount":3,"commentCount":4,"myParticipationStatus":"COMPLETED"}
                ]}}
                """
            return (200, Data(body.utf8))
        }
        let page = try await RoutineRepositoryImpl(networkManager: manager, accessToken: { token })
            .list(query: .init(participantID: id))
        let routine = try #require(page.routines?.first)
        #expect(page.totalCount == 5_000_000_000)
        #expect(routine.likedByMe == true)
        #expect(routine.inProgressCount == 2)
        #expect(routine.completedCount == 3)
        #expect(routine.commentCount == 4)
        #expect(routine.participation == .completed)
    }

    @Test func homeLoadsServerOrderAndNextCursor() async throws {
        let manager = network { request in
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
            let sort = items.first { $0.name == "sort" }?.value
            let cursor = items.first { $0.name == "cursor" }?.value
            let result: String
            if sort == "likes" {
                result = #"{"routines":[{"routineId":"c","title":"인기 루틴"}],"hasNext":false}"#
            } else if cursor == "next" {
                result = #"{"routines":[{"routineId":"a","title":"중복"},{"routineId":"b","title":"다음 루틴"}],"hasNext":false}"#
            } else {
                result = #"{"routines":[{"routineId":"a","title":"첫 루틴"}],"hasNext":true,"nextCursor":"next"}"#
            }
            return (200, Data("{\"isSuccess\":true,\"result\":\(result)}".utf8))
        }
        let repo = RoutineRepositoryImpl(networkManager: manager, accessToken: { token })
        let store = StoreOf<HomeReducer>(state: .init(), reducer: HomeReducer(repository: repo))
        store.send(.appeared)
        try await waitUntil { store.state.loaded }
        #expect(store.state.routines.map(\.id) == ["a"])
        store.send(.nextPage("a"))
        try await waitUntil { !store.state.isLoading }
        #expect(store.state.routines.map(\.id) == ["a", "b"])
        store.send(.sortChanged(.likes))
        try await waitUntil { !store.state.isLoading }
        #expect(store.state.routines.map(\.id) == ["c"])
    }

    @Test func commentFailurePreservesDraftAndServerResultReplacesIt() async throws {
        let manager = network { request in
            if request.httpMethod == "POST" {
                return (500, Data(#"{"isSuccess":false,"code":"TEST500","message":"다시 시도"}"#.utf8))
            }
            return (200, Data())
        }
        let comments = RoutineCommentRepositoryImpl(networkManager: manager, accessToken: { token })
        let reducer = RoutineDetailReducer(id: id, comments: comments)
        var initial = RoutineDetailReducer.State(title: "루틴")
        initial.loaded = true
        let store = StoreOf<RoutineDetailReducer>(state: initial, reducer: reducer)
        store.send(.commentChanged("  댓글  "))
        store.send(.submitCommentTapped)
        try await waitUntil { store.state.notice != nil }
        #expect(store.state.comments.isEmpty)
        #expect(store.state.commentDraft == "  댓글  ")
        // On retry the actual returned comment, including its server ID, replaces the draft.
        store.send(.commentSaved(.init(
            id: id, authorNickname: "사용자", profileImageURL: nil, content: "댓글",
            createdAt: nil, isMine: true)))
        #expect(store.state.comments.first?.id == id)
        #expect(store.state.commentDraft.isEmpty)
        #expect(store.state.commentCount == 1)
    }

    @Test func draftRetryReusesUploadedImages() async throws {
        var uploads = 0
        var saves = 0
        let manager = network { request in
            if request.url?.path == "/api/images/step" {
                uploads += 1
                return (
                    201,
                    Data(
                        """
                        {"isSuccess":true,"result":{"imageId":"\(id)"}}
                        """.utf8)
                )
            }
            saves += 1
            if saves == 1 {
                return (500, Data(#"{"isSuccess":false,"code":"TEST500","message":"다시 시도"}"#.utf8))
            }
            return (
                201,
                Data(
                    """
                    {"isSuccess":true,"result":{"routineId":"\(id)","title":"루틴 제목"}}
                    """.utf8)
            )
        }
        let saver = RoutineDraftSaver(
            images: ImageRepositoryImpl(networkManager: manager, accessToken: { token }),
            routines: RoutineRepositoryImpl(networkManager: manager, accessToken: { token }))
        let draft = RoutineDraft(
            title: "루틴 제목", introduction: nil,
            steps: [
                .init(image: .init(data: Data([1])), time: .init(hour: 7, minute: 0), title: "아침 운동하기", content: nil),
                .init(image: .init(data: Data([2])), time: .init(hour: 8, minute: 0), title: "아침 준비하기", content: nil),
            ])
        await #expect(throws: NetworkError.apiError(code: "TEST500", message: "다시 시도")) {
            try await saver.save(draft)
        }
        #expect(try await saver.save(draft).id == id)
        #expect(saves == 2)
        #expect(uploads == 2)
    }

    @Test func editsUseTheCorrectPUTAndKeepUnchangedImages() async throws {
        let replacementID = "01KB0000000000000000DEF002"
        var savedPaths: [String] = []
        var uploads = 0
        let manager = network { request in
            let path = try #require(request.url?.path)
            if path == "/api/images/step" {
                uploads += 1
                return (201, Data("""
                    {"isSuccess":true,"result":{"imageId":"\(replacementID)"}}
                    """.utf8))
            }
            #expect(request.httpMethod == "PUT")
            savedPaths.append(path)
            let body = try request.httpBody ?? request.httpBodyStream.map { stream in
                stream.open()
                defer { stream.close() }
                var data = Data()
                var buffer = [UInt8](repeating: 0, count: 1024)
                while stream.hasBytesAvailable {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    guard count >= 0 else { throw URLError(.cannotDecodeRawData) }
                    if count == 0 { break }
                    data.append(contentsOf: buffer.prefix(count))
                }
                return data
            }
            let json = try JSONSerialization.jsonObject(with: #require(body)) as? [String: Any]
            let cards = try #require(json?["cards"] as? [[String: Any]])
            #expect(cards.compactMap { $0["imageId"] as? String } == [id, replacementID])
            if savedPaths.count == 1 {
                return (500, Data(#"{"isSuccess":false,"code":"TEST500","message":"다시 시도"}"#.utf8))
            }
            return (200, Data("""
                {"isSuccess":true,"result":{"routineId":"\(id)","title":"수정한 루틴"}}
                """.utf8))
        }
        let saver = RoutineDraftSaver(
            images: ImageRepositoryImpl(networkManager: manager, accessToken: { token }),
            routines: RoutineRepositoryImpl(networkManager: manager, accessToken: { token }))
        let draft = RoutineDraft(title: "수정한 루틴", introduction: nil, steps: [
            .init(photo: .stored(id: id, url: nil), time: .init(hour: 7, minute: 0), title: "아침 준비하기", content: nil),
            .init(image: .init(data: Data([1])), time: .init(hour: 8, minute: 0), title: "아침 운동하기", content: nil),
        ])
        await #expect(throws: NetworkError.apiError(code: "TEST500", message: "다시 시도")) {
            try await saver.update(draft, target: .routine(id: id))
        }
        try await saver.update(draft, target: .routine(id: id))
        try await saver.update(draft, target: .participation(routineID: id, participantID: id))
        #expect(uploads == 1)
        #expect(savedPaths == ["/api/routines/\(id)", "/api/routines/\(id)", "/api/routines/\(id)/participation-results/\(id)"])
    }

    @Test func detailOnlyEnablesEditingForTheOwner() {
        let owner = RoutineOwnerEntity(id: id, nickname: "작성자", profileImageURL: nil)
        let detail = RoutineDetailEntity(
            id: id, title: "서버 루틴", content: nil, owner: owner, cards: nil,
            likeCount: nil, commentCount: nil, createdAt: nil, updatedAt: nil)
        let interactions = RoutineInteractions(
            likeCount: 0, likedByMe: false, inProgressCount: 0, completedCount: 0, participation: .completed)
        for resultID in [nil, id] {
            for userID in [id, "another-user"] {
                let reducer = RoutineDetailReducer(id: id, userID: userID, resultParticipantID: resultID)
                var state = RoutineDetailReducer.State(title: "상세")
                state.isParticipationResult = resultID != nil
                #expect(!state.canEdit)
                _ = reducer.reduce(&state, with: .loaded(detail, [], interactions))
                #expect(state.canEdit == (userID == id))
                state.isBusy = true
                #expect(!state.canEdit)
            }
        }
    }

    @Test func relatedScreenLoadsEmptyStateAndRetriesAfterFailure() async throws {
        var attempts = 0
        let manager = network { request in
            #expect(request.url?.path == "/api/routines/\(id)/participation-results")
            attempts += 1
            if attempts == 1 {
                return (500, Data(#"{"isSuccess":false,"code":"TEST500","message":"다시 시도"}"#.utf8))
            }
            return (200, Data(#"{"isSuccess":true,"result":{"results":[],"totalCount":0}}"#.utf8))
        }
        let repository = RoutineRepositoryImpl(networkManager: manager)
        let store = Store(state: .loading, reducer: RoutineRelatedLoader {
            try await repository.participationResults(routineID: id)
        })
        store.send(.load)
        try await waitUntil { store.state == .failed("다시 시도") }
        store.send(.load)
        try await waitUntil { store.state == .loaded(.init(results: [], totalCount: 0)) }
    }

    @Test func profilePatchDistinguishesOmissionNullAndValue() throws {
        for (update, expectedBio) in [
            (UserProfileUpdate(nickname: "새 이름"), nil),
            (UserProfileUpdate(bio: .clear), NSNull()),
            (UserProfileUpdate(bio: .set("한 줄 소개")), "한 줄 소개" as NSObject)
        ] {
            let data = try JSONEncoder().encode(UserProfileUpdateRequestDTO(update: update))
            let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: NSObject])
            #expect(json["bio"] == expectedBio)
            #expect(json["nickname"] as? String == update.nickname)
        }
        #expect(throws: UserProfileUpdate.ValidationError.nickname) {
            try UserEndpoint.updateProfile(.init(nickname: "한"), headers: [:])
        }
        #expect(throws: UserProfileUpdate.ValidationError.bio) {
            try UserEndpoint.updateProfile(.init(bio: .set(String(repeating: "가", count: 51))), headers: [:])
        }
    }

    @Test func profileEditRetriesPatchWithoutUploadingAgain() async throws {
        var uploads = 0
        var patches = 0
        let manager = network { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
            #expect(request.value(forHTTPHeaderField: "X-User-Id") == nil)
            let path = request.url?.path
            var bytes = request.httpBody ?? Data()
            if let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var buffer = [UInt8](repeating: 0, count: 1024)
                while stream.hasBytesAvailable {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count <= 0 { break }
                    bytes.append(contentsOf: buffer.prefix(count))
                }
            }
            if path == "/api/images/profile" {
                uploads += 1
                #expect(request.httpMethod == "POST")
                #expect(request.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data") == true)
                #expect(String(decoding: bytes, as: UTF8.self).contains(#"name="file""#))
                return (201, Data("""
                    {"isSuccess":true,"result":{"imageId":"\(id)"}}
                    """.utf8))
            }
            patches += 1
            #expect(path == "/api/users/me")
            #expect(request.httpMethod == "PATCH")
            let body = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
            #expect(body["bio"] is NSNull)
            #expect(body["nickname"] as? String == "새 이름")
            #expect(body["profileImagePublicId"] as? String == id)
            if patches == 1 {
                return (500, Data(#"{"isSuccess":false,"code":"TEST500","message":"다시 시도"}"#.utf8))
            }
            return (200, Data("""
                {"isSuccess":true,"result":{"publicId":"\(id)","nickname":"새 이름","profileImagePublicId":"\(id)","bio":null}}
                """.utf8))
        }
        let reducer = MyProfileReducer(
            users: UserRepositoryImpl(networkManager: manager, accessToken: { token }),
            images: ImageRepositoryImpl(networkManager: manager, accessToken: { token }))
        let store = StoreOf<MyProfileReducer>(state: .init(nickname: "이전 이름", introduction: "이전 소개"), reducer: reducer)
        store.send(.editTapped)
        store.send(.nicknameChanged("새 이름"))
        store.send(.bioChanged("  "))
        store.send(.photoChanged(.init(data: Data("photo".utf8), fileName: "profile.jpg", mimeType: "image/jpeg")))
        store.send(.saveTapped)
        try await waitUntil { store.state.editError != nil }
        #expect(store.state.introduction == "이전 소개")
        #expect(store.state.edit?.uploadedImageID == id)
        store.send(.saveTapped)
        try await waitUntil { store.state.updatedProfile != nil }
        #expect(store.state.edit == nil)
        #expect(store.state.introduction.isEmpty)
        #expect(store.state.updatedProfile?.profileImageID == id)
        #expect(uploads == 1)
        #expect(patches == 2)
    }

    private func waitUntil(_ condition: @MainActor () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        try #require(condition())
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

    @Test func userBioDTOAndMapping() throws {
        let json = #"{"isSuccess":true,"result":{"publicId":"user","nickname":"닉네임","profileImagePublicId":"image","bio":"매일 조금씩 운동해요."}}"#
        let dto = try decode(APIResponseDTO<UserResponseDTO>.self, json).value()
        #expect(dto.bio == "매일 조금씩 운동해요.")
        let entity = try UserMapper.map(dto)
        #expect(entity.bio == dto.bio)
        #expect(entity.profileImageID == "image")
        for bioJSON in ["", #","bio":null"#, #","bio":"""#] {
            let userJSON = "{\"publicId\":\"user\",\"nickname\":\"닉네임\"\(bioJSON)}"
            let user = try decode(UserResponseDTO.self, userJSON)
            #expect(try UserMapper.map(user).bio == (bioJSON.contains("\"\"") ? "" : nil))
        }
    }

    @Test func testAccountLeaseUsesBearerAndChecksAccountIdentity() async throws {
        let manager = network { request in
            let path = request.url?.path ?? ""
            let method = request.httpMethod ?? ""
            let result: String
            switch (method, path) {
            case ("GET", "/api/test-accounts"):
                #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
                result = """
                    [{"publicId":"\(id)","nickname":"테스트","slot":1,"available":true}]
                    """
            case ("POST", "/api/test-accounts/\(id)/claim"):
                #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
                result = """
                    {"publicId":"\(id)","accessToken":"\(token)","expiresAt":"2026-11-22T03:00:00.123456"}
                    """
            case ("POST", "/api/test-accounts/\(id)/heartbeat"):
                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
                result = #"{"expiresAt":"2026-11-22T03:01:00.123456"}"#
            case ("DELETE", "/api/test-accounts/\(id)/claim"):
                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
                result = "null"
            case ("GET", "/api/routines/\(id)/comments"):
                #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
                result = "[]"
            default:
                Issue.record("Unexpected request: \(method) \(path)")
                return (404, Data())
            }
            return (200, Data("{\"isSuccess\":true,\"result\":\(result)}".utf8))
        }
        let accounts = TestAccountRepositoryImpl(network: manager)
        let entries = try await accounts.list()
        #expect(entries == [.init(id: id, slot: 1, nickname: "테스트", available: true)])
        let lease = try await accounts.claim(accountID: id)
        #expect(lease.accountID == id)
        let expiry = try await accounts.heartbeat(lease)
        #expect(expiry.timeIntervalSince(lease.expiresAt) == 60)
        try await accounts.release(lease)
        let anonymous = RoutineCommentRepositoryImpl(networkManager: manager)
        #expect(try await anonymous.list(routineID: id).isEmpty)
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
        let failure = try decode(
            APIResponseDTO<[UserResponseDTO]>.self,
            """
            {"isSuccess":false,"code":"COMMON400","message":"입력 오류","result":{"nickname":"길이 오류"}}
            """)
        #expect(failure.fieldErrors == ["nickname": "길이 오류"])
        #expect(throws: NetworkError.apiError(code: "COMMON400", message: "입력 오류")) { try failure.value() }
        #expect(try decode(RoutineCardResponseDTO.self, #"{"title":"제목"}"#).imageId == nil)
    }

    private var input: RoutineSaveInput {
        RoutineSaveInput(
            title: "나의 아침 루틴", content: nil,
            cards: [RoutineCardEntity(imageID: id, title: "기상 후 물 마시기", content: nil, time: "07:30")])
    }

    @Test func endpoints() throws {
        let headers = try Mapping.bearerHeaders { token }
        let cases: [(APIEndpoint, String, String, Bool)] = [
            (try UserEndpoint.updateProfile(.init(nickname: "닉네임"), headers: headers), "PATCH", "/api/users/me", true),
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
            (ImageEndpoint.uploadStep(headers: headers), "POST", "/api/images/step", true),
            (ImageEndpoint.uploadProfile(headers: headers), "POST", "/api/images/profile", true),
            (try ImageEndpoint.data(id: id), "GET", "/api/images/\(id)", false),
        ]
        for (target, method, path, authenticated) in cases {
            let request = try target.asURLRequest()
            #expect(request.httpMethod == method)
            #expect(request.url?.path == path)
            #expect(request.value(forHTTPHeaderField: "Authorization") == (authenticated ? "Bearer \(token)" : nil))
            #expect(request.value(forHTTPHeaderField: "X-Device-Token") == nil)
        }
        let query = RoutineListQuery(sort: .likes, authorID: id, participantID: id, cursor: "a+b/=", size: 50)
        let request = try RoutineEndpoint.list(query: query).asURLRequest()
        let items = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
        let values = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
        #expect(values == ["sort": "likes", "authorId": id, "participantId": id, "cursor": "a+b/=", "size": "50"])
        let save = try RoutineEndpoint.save(input: input, headers: headers).asURLRequest()
        let saveBody = try #require(save.httpBody)
        let object = try JSONSerialization.jsonObject(with: saveBody)
        let json = try #require(object as? [String: Any])
        #expect(json["title"] as? String == input.title)
        #expect((json["cards"] as? [[String: Any]])?.first?["imageId"] as? String == id)
        let userBody = try UserEndpoint.updateProfile(.init(nickname: "닉네임"), headers: headers).asURLRequest().httpBody
        #expect(try JSONSerialization.jsonObject(with: #require(userBody)) as? [String: String] == ["nickname": "닉네임"])
        let commentBody = try RoutineCommentEndpoint.save(routineID: id, content: "댓글", headers: headers).asURLRequest()
            .httpBody
        #expect(try JSONSerialization.jsonObject(with: #require(commentBody)) as? [String: String] == ["content": "댓글"])
    }

    @Test func validation() throws {
        for value in ["", "  ", "bad\r\nheader", "bad token"] {
            #expect(throws: DataContractError.missingAccessToken) { try Mapping.bearerHeaders { value } }
        }
        #expect(throws: (any Error).self) { try RoutineEndpoint.detail(id: "../users") }
        #expect(throws: (any Error).self) { try RoutineEndpoint.list(query: .init(size: 0)) }
        #expect(throws: (any Error).self) { try RoutineEndpoint.list(query: .init(size: 51)) }
        #expect(throws: (any Error).self) {
            try RoutineEndpoint.save(input: .init(title: "짧음", content: nil, cards: []), headers: [:])
        }
        #expect(throws: (any Error).self) {
            try UserEndpoint.updateProfile(.init(nickname: String(repeating: "가", count: 11)), headers: [:])
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
                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
            }
            #expect(request.value(forHTTPHeaderField: "X-Device-Token") == nil)
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
                result = user
            } else if path == "/api/routines" && method == "GET" {
                result = #"{"routines":[],"hasNext":false}"#
            } else {
                result = #"{"routineId":"routine","title":"루틴 제목"}"#
            }
            return (200, Data("{\"isSuccess\":true,\"result\":\(result)}".utf8))
        }
        let user: any UserRepository = UserRepositoryImpl(networkManager: network, accessToken: { token })
        #expect(try await user.updateProfile(.init(nickname: "닉네임")).id == "user")
        #expect(try await user.me().nickname == "닉네임")
        let routine: any RoutineRepository = RoutineRepositoryImpl(networkManager: network, accessToken: { token })
        #expect(try await routine.list(query: .init()).routines == [])
        #expect(try await routine.detail(id: id).id == "routine")
        #expect(try await routine.create(input: input).title == "루틴 제목")
        #expect(try await routine.update(id: id, input: input).id == "routine")
        try await routine.delete(id: id)
        let comment: any RoutineCommentRepository = RoutineCommentRepositoryImpl(
            networkManager: network, accessToken: { token })
        #expect(try await comment.list(routineID: id).count == 1)
        #expect(try await comment.create(routineID: id, content: "댓글").id == "comment")
        #expect(try await comment.update(routineID: id, commentID: id, content: "댓글").content == "댓글")
        try await comment.delete(routineID: id, commentID: id)
        let image: any ImageRepository = ImageRepositoryImpl(networkManager: network, accessToken: { token })
        #expect(
            try await image.uploadGeneral(
                input: .init(data: Data("image-bytes".utf8), fileName: "test.jpg", mimeType: "image/jpeg")
            ).id == "image")
        #expect(try await image.data(id: id) == Data([1, 2, 3]))
    }

    @Test func repositoryFailures() async throws {
        var manager = network { _ in (403, Data(#"{"code":"DENIED","message":"거절"}"#.utf8)) }
        var repo = UserRepositoryImpl(networkManager: manager, accessToken: { token })
        await #expect(throws: NetworkError.apiError(code: "DENIED", message: "거절")) { try await repo.me() }
        manager = network { _ in (200, Data(#"{"isSuccess":false,"code":"FAILED","message":"실패"}"#.utf8)) }
        repo = UserRepositoryImpl(networkManager: manager, accessToken: { token })
        await #expect(throws: NetworkError.apiError(code: "FAILED", message: "실패")) { try await repo.me() }
        manager = network { _ in (200, Data(#"{"isSuccess":true,"result":{"nickname":"이름"}}"#.utf8)) }
        repo = UserRepositoryImpl(networkManager: manager, accessToken: { token })
        await #expect(throws: DataContractError.missingField("publicId")) { try await repo.me() }
        manager = network { _ in
            Issue.record("빈 토큰으로 요청하면 안 됩니다.")
            return (500, Data())
        }
        repo = UserRepositoryImpl(networkManager: manager, accessToken: { "" })
        await #expect(throws: DataContractError.missingAccessToken) { try await repo.me() }
        let image = ImageRepositoryImpl(networkManager: manager, accessToken: { token })
        await #expect(throws: DataContractError.invalidValue("file")) {
            try await image.upload(input: .init(data: Data(), fileName: "image.jpg", mimeType: "image/jpeg"))
        }
        for (fileName, mimeType) in [
            ("bad\r\nname", "image/jpeg"), ("bad\0name", "image/jpeg"), ("image.jpg", "image/jpeg;invalid"),
        ] {
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
