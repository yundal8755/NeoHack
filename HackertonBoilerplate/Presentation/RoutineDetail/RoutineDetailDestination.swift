import HackertonCore
import MVICore
import SwiftUI

struct RoutineDetailDestination: View {
    @StateObject private var store: StoreOf<RoutineDetailReducer>

    init(state: RoutineDetailReducer.State) {
        _store = StateObject(wrappedValue: StoreOf<RoutineDetailReducer>(state: state, reducer: RoutineDetailReducer()))
    }

    var body: some View { RoutineDetailView(store: store) }
}

