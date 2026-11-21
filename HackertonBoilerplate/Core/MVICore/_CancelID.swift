import Foundation

struct _CancelID: Hashable {
    private let uuid = UUID()
    let id: AnyHashable

    init(id: AnyHashable) {
        self.id = id
    }
}
