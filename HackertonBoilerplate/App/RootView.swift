import HackertonCore
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("홈", systemImage: "house") {
                HomeView()
            }

            Tab("설정", systemImage: "gearshape") {
                Text("설정").font(AppFont.title)
                    .accessibilityIdentifier(AccessibilityID.Root.settingsScreen)
            }
        }
    }
}

#Preview {
    RootView()
}
