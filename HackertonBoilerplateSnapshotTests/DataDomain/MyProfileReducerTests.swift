import Foundation
@testable import HackertonBoilerplate
import Testing

struct MyProfileReducerTests {
    @Test func 탭을_바꾸면_해당_목록을_보여준다() {
        var state = MockRoutineData.profile
        let reducer = MyProfileReducer()
        #expect(state.selectedTab == .mine)
        #expect(state.visibleRoutines.count == 3)
        #expect(state.visibleRoutines.allSatisfy { $0.detail.isOwner })
        _ = reducer.reduce(&state, with: .tabSelected(.participating))
        #expect(state.visibleRoutines == state.participatingRoutines)
        #expect(state.visibleRoutines.count == 5)
        #expect(state.visibleRoutines.allSatisfy { !$0.detail.isOwner && $0.detail.participation != .notJoined })
        _ = reducer.reduce(&state, with: .editTapped)
        #expect(state.notice == "프로필 편집 화면은 준비 중입니다.")
        #expect(state.edit == nil)
        _ = reducer.reduce(&state, with: .noticeDismissed)
        #expect(state.notice == nil)
    }
}

struct ProfileEditReducerTests {
    private static let reducer = MyProfileReducer(users: UnusedUserRepository(), images: UnusedImageRepository())

    private func editing() -> MyProfileReducer.State {
        var state = MyProfileReducer.State(nickname: "김햄찌", introduction: "아침형 햄스터")
        _ = Self.reducer.reduce(&state, with: .editTapped)
        return state
    }

    @Test func 서버_계정이면_프로필_편집을_누를_때_현재_값으로_편집을_연다() {
        let state = editing()
        #expect(state.edit == .init(nickname: "김햄찌", bio: "아침형 햄스터"))
        #expect(state.notice == nil)
        #expect(!state.canSave)
    }

    @Test(arguments: [
        ("김", false),
        ("김햄", true),
        ("  김햄  ", true),
        ("열글자닉네임입니다요", true),
        ("   ", false),
        ("김햄찌", false),
    ])
    func 닉네임_길이가_맞고_바뀐_내용이_있을_때만_저장할_수_있다(nickname: String, canSave: Bool) {
        var state = editing()
        _ = Self.reducer.reduce(&state, with: .nicknameChanged(nickname))
        #expect(state.canSave == canSave)
    }

    @Test func 바뀐_내용이_없으면_뒤로_가기에_바로_닫힌다() {
        var state = editing()
        _ = Self.reducer.reduce(&state, with: .closeEditor)
        #expect(state.edit == nil)
        #expect(!state.isDiscardAlertPresented)
    }

    @Test func 바뀐_내용이_있으면_뒤로_가기에_나갈지_묻는다() {
        var state = editing()
        _ = Self.reducer.reduce(&state, with: .bioChanged("저녁형 햄스터"))
        _ = Self.reducer.reduce(&state, with: .closeEditor)
        #expect(state.isDiscardAlertPresented)
        #expect(state.edit?.bio == "저녁형 햄스터")

        _ = Self.reducer.reduce(&state, with: .discardCancelled)
        #expect(!state.isDiscardAlertPresented)
        #expect(state.edit?.bio == "저녁형 햄스터")

        _ = Self.reducer.reduce(&state, with: .closeEditor)
        _ = Self.reducer.reduce(&state, with: .editorDismissed)
        #expect(state.edit == nil)
        #expect(!state.isDiscardAlertPresented)
        #expect(state.introduction == "아침형 햄스터")
    }

    @Test func 저장_중에는_뒤로_가기와_저장을_무시한다() {
        var state = editing()
        _ = Self.reducer.reduce(&state, with: .nicknameChanged("새 이름"))
        state.isSaving = true
        #expect(!state.canSave)
        _ = Self.reducer.reduce(&state, with: .closeEditor)
        #expect(state.edit != nil)
        #expect(!state.isDiscardAlertPresented)
    }

    @Test func 저장에_성공하면_편집을_닫고_안내한다() {
        var state = editing()
        state.isSaving = true
        _ = Self.reducer.reduce(
            &state, with: .profileSaved(UserEntity(id: "me", nickname: "새 이름", profileImageID: nil, bio: "새 소개")))
        #expect(state.edit == nil)
        #expect(!state.isSaving)
        #expect(state.nickname == "새 이름")
        #expect(state.introduction == "새 소개")
        #expect(state.notice == "프로필을 저장했어요.")
    }
}

/// 상태 전이만 검증하는 테스트에서 넣는 대역. 호출되면 실패로 기록한다.
private struct UnusedUserRepository: UserRepository {
    func updateProfile(_ update: UserProfileUpdate) async throws -> UserEntity {
        Issue.record("updateProfile가 호출되면 안 됩니다.")
        throw CancellationError()
    }

    func me() async throws -> UserEntity {
        Issue.record("me가 호출되면 안 됩니다.")
        throw CancellationError()
    }
}

private struct UnusedImageRepository: ImageRepository {
    func upload(input: ImageUploadInput) async throws -> UploadedImageEntity {
        Issue.record("upload가 호출되면 안 됩니다.")
        throw CancellationError()
    }

    func uploadProfile(input: ImageUploadInput) async throws -> UploadedImageEntity {
        Issue.record("uploadProfile가 호출되면 안 됩니다.")
        throw CancellationError()
    }

    func data(id: String) async throws -> Data {
        Issue.record("data가 호출되면 안 됩니다.")
        throw CancellationError()
    }
}
