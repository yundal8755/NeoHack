import MVICore
import SnapshotTesting
import SwiftUI
import Testing

@testable import HackertonBoilerplate

@MainActor
@Suite(.snapshots(record: .missing))
struct RoutineRelatedViewsSnapshotTests {
    private let id = "01KB0000000000000000DEF001"
    private var profile: UserEntity {
        UserEntity(id: id, nickname: "아침친구", profileImageID: nil, bio: "매일 조금씩 움직여요.")
    }

    @Test(arguments: ["loaded", "empty", "error"])
    func results(stateName: String) {
        let result = RoutineParticipationResults.Summary(
            participant: .init(id: id, nickname: profile.nickname, profileImageURL: nil),
            title: "오늘도 아침 운동", content: nil, thumbnailURL: nil, completedAt: nil)
        let state: RoutineRelatedLoader<RoutineParticipationResults>.State = switch stateName {
        case "loaded": .loaded(.init(results: [result], totalCount: 1))
        case "empty": .loaded(.init(results: [], totalCount: 0))
        default: .failed("잠시 후 다시 시도해 주세요.")
        }
        let store = Store(state: state, reducer: RoutineRelatedLoader<RoutineParticipationResults> {
            Issue.record("스냅샷 준비 상태에서는 요청을 보내지 않습니다.")
            return .init(results: [], totalCount: 0)
        })
        let session = ProfileSession(profile: profile, repositories: AppContainer.shared.session(token: "snapshot"))
        snapshot(ParticipationResultsView(routineID: id, session: session, store: store) {}, name: "results.\(stateName)")
    }

    @Test(arguments: ["loaded", "error"])
    func publicProfile(stateName: String) {
        let state: RoutineRelatedLoader<UserEntity>.State =
            stateName == "loaded" ? .loaded(profile) : .failed("프로필을 찾을 수 없어요.")
        let store = Store(state: state, reducer: RoutineRelatedLoader<UserEntity> {
            Issue.record("스냅샷 준비 상태에서는 요청을 보내지 않습니다.")
            return profile
        })
        let users = AppContainer.shared.session(token: "snapshot").users
        snapshot(PublicProfileView(publicID: id, users: users, store: store), name: "profile.\(stateName)")
    }

    private func snapshot(_ view: some View, name: String) {
        assertSnapshot(
            of: view, as: .image(layout: .fixed(width: 402, height: 980), traits: .init(userInterfaceStyle: .light)),
            named: name)
    }
}
