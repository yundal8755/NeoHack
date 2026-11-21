import SwiftUI

struct ProfileAvatar: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                NetworkImageView(
                    url: url, cornerRadius: size / 2,
                    downsamplingSize: CGSize(width: size, height: size),
                    borderColor: nil, showsLoadingText: false)
            } else {
                Image("RoutineDetailAvatar").resizable()
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
