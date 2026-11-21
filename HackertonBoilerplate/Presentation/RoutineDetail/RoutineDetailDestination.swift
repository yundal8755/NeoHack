import HackertonCore
import MVICore
import SwiftUI

struct RoutineDetailDestination: View {
    @StateObject private var store: StoreOf<RoutineDetailReducer>

    private let onDelete: () -> Void

    init(id: String, session: ProfileSession, onDelete: @escaping () -> Void) {
        var state = RoutineDetailReducer.State(title: "루틴 상세")
        state.isLive = true
        _store = StateObject(wrappedValue: StoreOf<RoutineDetailReducer>(
            state: state, reducer: RoutineDetailReducer(
                id: id, userID: session.profile.id, routines: session.repositories.routines,
                comments: session.repositories.comments)))
        self.onDelete = onDelete
    }

    init(state: RoutineDetailReducer.State) {
        _store = StateObject(wrappedValue: StoreOf<RoutineDetailReducer>(state: state, reducer: RoutineDetailReducer()))
        onDelete = {}
    }

    var body: some View { RoutineDetailView(store: store, onDelete: onDelete) }
}

