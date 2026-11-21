import Foundation

package struct _CancelID: Hashable {
    private let uuid = UUID()
    package let id: AnyHashable

    package init(id: AnyHashable) {
        self.id = id
    }
}
