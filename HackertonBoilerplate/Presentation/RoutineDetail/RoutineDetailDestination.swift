import HackertonCore
import MVICore
import SwiftUI

struct RoutineDetailDestination: View {
    @StateObject private var store: StoreOf<RoutineDetailReducer>
    private let onBack: () -> Void

    init(state: RoutineDetailReducer.State, onBack: @escaping () -> Void) {
        self.onBack = onBack
        _store = StateObject(wrappedValue: StoreOf<RoutineDetailReducer>(state: state, reducer: RoutineDetailReducer()))
    }

    var body: some View { RoutineDetailView(store: store, onBack: onBack) }
}
