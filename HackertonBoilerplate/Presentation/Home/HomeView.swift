import SwiftUI
import HackertonCore

struct HomeView: View {
    @State private var isPickingRoutineImages = false
    
    var body: some View {
        VStack(spacing: 0) {
            AppTopBar("서비스명", leading: .add { isPickingRoutineImages = true })

            Text("홈").font(AppFont.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier(AccessibilityID.Root.homeScreen)
        }
        .routineCreateFlow(isPickingImages: $isPickingRoutineImages)
    }
}

#Preview {
    HomeView()
}
