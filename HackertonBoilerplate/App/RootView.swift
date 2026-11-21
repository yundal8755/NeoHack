import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("홈", systemImage: "house") {
                Text("홈").font(AppFont.title)
            }

            Tab("설정", systemImage: "gearshape") {
                Text("설정").font(AppFont.title)
            }
        }
    }
}

#Preview {
    RootView()
}
