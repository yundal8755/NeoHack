import SwiftUI
import HackertonCore

struct HomeView: View {
    @State private var isPickingRoutineImages = false
    
    var body: some View {
        VStack(spacing: 0) {
            AppTopBar("서비스명", leading: .add { isPickingRoutineImages = true })

            Text("홈").font(AppFont.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .accessibilityIdentifier(AccessibilityID.Root.homeScreen)
        }
        // 플러스 버튼 외에 화면을 오른쪽으로 밀어도 루틴 만들기를 연다.
        .routineCreateSwipe { isPickingRoutineImages = true }
        .routineCreateFlow(isPickingImages: $isPickingRoutineImages)
    }
}

#Preview {
    HomeView()
}
