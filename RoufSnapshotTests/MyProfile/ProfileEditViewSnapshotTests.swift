import RoufCore
import MVICore
import SnapshotTesting
import SwiftUI
import Testing
@testable import Rouf

/// 프로필 편집 화면을 State별로 찍는다. 프로필 사진이 없는 계정이라 기본 이미지로 찍힌다.
@MainActor
@Suite(.snapshots(record: .missing))
struct ProfileEditViewSnapshotTests {
    typealias Feature = MyProfileReducer

    static func editing(
        nickname: String = "김햄찌", bio: String = "매일 아침 루틴을 지키는 햄스터",
        configure: (inout Feature.State) -> Void = { _ in }
    ) -> Feature.State {
        var state = Feature.State(nickname: "김햄찌", introduction: "매일 아침 루틴을 지키는 햄스터")
        state.edit = .init(nickname: nickname, bio: bio)
        configure(&state)
        return state
    }

    static let states: [(String, Feature.State)] = [
        ("unchanged", editing()),
        ("edited", editing(nickname: "부지런한햄찌", bio: "")),
        ("invalidNickname", editing(nickname: "김")),
        ("saving", editing(nickname: "부지런한햄찌") { $0.isSaving = true }),
        ("saveFailed", editing(nickname: "부지런한햄찌") { $0.editError = "이미 사용 중인 닉네임이에요." }),
    ]

    @Test(arguments: ["unchanged", "edited", "invalidNickname", "saving", "saveFailed"])
    func profileEditView(name: String) throws {
        let state = try #require(Self.states.first { $0.0 == name }?.1)
        let store = StoreOf<Feature>(state: state, reducer: Feature())
        assertSnapshot(of: ProfileEditView(store: store), as: .screen, named: name)
    }
}
