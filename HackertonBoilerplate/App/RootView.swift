import HackertonCore
import SwiftUI
import MVICore

struct RootView: View {
    // shortcut: 홈 API가 없어 Figma 샘플을 표시한다. Repository 연동 시 실제 조회 상태로 교체한다.
    @StateObject private var homeStore = StoreOf<HomeReducer>(state: HomePreview.state, reducer: HomeReducer())

    var body: some View {
        HomeView(store: homeStore) {
            homeStore.send(.routinesUpdated(HomePreview.state.routines))
        }
    }
}

#Preview {
    RootView()
}
