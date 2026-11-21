import Foundation

struct FeedbackMessage: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: FeedbackKind
    let title: String
    let message: String
    let actionTitle: String?

    init(
        id: UUID = UUID(),
        kind: FeedbackKind,
        title: String,
        message: String,
        actionTitle: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
    }
}

enum FeedbackKind: Equatable, Sendable {
    case success
    case info
    case warning
    case error

    var systemImage: String {
        switch self {
        case .success:
            "checkmark.seal.fill"
        case .info:
            "info.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .error:
            "xmark.octagon.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .success:
            "Success"
        case .info:
            "Information"
        case .warning:
            "Warning"
        case .error:
            "Error"
        }
    }
}

enum FeedbackToastEdge: Equatable, Sendable {
    case top
    case bottom
}

enum FeedbackPresentation: Equatable, Sendable {
    case toast(edge: FeedbackToastEdge)
    case alert
    case bottomSheet

    static var topToast: FeedbackPresentation { .toast(edge: .top) }
    static var bottomToast: FeedbackPresentation { .toast(edge: .bottom) }
}
