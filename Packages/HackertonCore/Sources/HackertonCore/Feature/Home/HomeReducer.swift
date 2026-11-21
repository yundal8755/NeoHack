import Foundation
import MVICore

public struct HomeReducer: Reducer {
    public init() {}

    /// 홈 UI 표시용 데이터. 서버 Entity 계약이 준비되면 Mapper 결과로 교체한다.
    public struct Routine: Equatable, Identifiable {
        public let id: Int
        public let nickname: String
        public let introduction: String
        public let createdAt: Date
        public let detail: RoutineDetailReducer.State

        public init(id: Int, nickname: String, introduction: String, createdAt: Date, detail: RoutineDetailReducer.State) {
            self.id = id
            self.nickname = nickname
            self.introduction = introduction
            self.createdAt = createdAt
            self.detail = detail
        }
    }

    public enum Sort: String, CaseIterable {
        case latest = "최신순"
        case likes = "인기순"
        case participation = "참여순"
    }

    public struct State: Equatable {
        public var routines: [Routine]
        public var sort: Sort

        public init(routines: [Routine] = [], sort: Sort = .latest) {
            self.routines = routines
            self.sort = sort
        }

        public var sortedRoutines: [Routine] {
            routines.sorted { lhs, rhs in
                if sort == .likes, lhs.detail.likeCount != rhs.detail.likeCount {
                    return lhs.detail.likeCount > rhs.detail.likeCount
                }
                if sort == .participation {
                    let leftCount = lhs.detail.participatingCount + lhs.detail.completedCount
                    let rightCount = rhs.detail.participatingCount + rhs.detail.completedCount
                    if leftCount != rightCount { return leftCount > rightCount }
                }
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.id < rhs.id
            }
        }
    }

    public enum Action {
        case sortChanged(Sort)
        case routinesUpdated([Routine])
    }

    public func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case let .sortChanged(sort): state.sort = sort
        case let .routinesUpdated(routines): state.routines = routines
        }
        return .none
    }
}
