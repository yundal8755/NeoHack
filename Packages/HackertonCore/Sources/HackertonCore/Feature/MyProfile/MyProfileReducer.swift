import MVICore

public struct MyProfileReducer: Reducer {
    public init() {}

    public enum Tab: Equatable {
        case mine
        case participating
    }

    public struct State: Equatable {
        public var nickname: String
        public var introduction: String
        public var myRoutines: [HomeReducer.Routine]
        /// 최신 참여순으로 전달받은 목록. 루틴 생성일과 참여일은 다르므로 다시 정렬하지 않는다.
        public var participatingRoutines: [HomeReducer.Routine]
        public var selectedTab: Tab = .mine
        public var notice: String?

        public init(nickname: String, introduction: String, myRoutines: [HomeReducer.Routine] = [], participatingRoutines: [HomeReducer.Routine] = []) {
            self.nickname = nickname
            self.introduction = introduction
            self.myRoutines = myRoutines
            self.participatingRoutines = participatingRoutines
        }

        public var visibleRoutines: [HomeReducer.Routine] {
            switch selectedTab {
            case .mine:
                myRoutines.sorted {
                    if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
                    return $0.id < $1.id
                }
            case .participating: participatingRoutines
            }
        }
    }

    public enum Action {
        case tabSelected(Tab)
        case editTapped
        case noticeDismissed
    }

    public func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case let .tabSelected(tab): state.selectedTab = tab
        case .editTapped: state.notice = "프로필 편집 화면은 준비 중이에요."
        case .noticeDismissed: state.notice = nil
        }
        return .none
    }
}
