import SwiftUI

final class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()

    private init() { }

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
