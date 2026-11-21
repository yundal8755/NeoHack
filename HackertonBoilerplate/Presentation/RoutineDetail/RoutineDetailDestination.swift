import HackertonCore
import MVICore
import SwiftUI

struct RoutineDetailDestination: View {
    @StateObject private var store: StoreOf<RoutineDetailReducer>

    private let onBack: () -> Void
    private let session: ProfileSession?
    private let routineID: String?
    private let onParticipationCompleted: () -> Void
    private let onDelete: () -> Void

    init(id: String, session: ProfileSession, resultParticipantID: String? = nil, onParticipationCompleted: @escaping () -> Void = {}, onBack: @escaping () -> Void, onDelete: @escaping () -> Void) {
        var state = RoutineDetailReducer.State(title: "루틴 상세")
        state.isLive = true
        state.isParticipationResult = resultParticipantID != nil
        self.session = session
        routineID = id
        self.onParticipationCompleted = onParticipationCompleted
        _store = StateObject(
            wrappedValue: StoreOf<RoutineDetailReducer>(
                state: state,
                reducer: RoutineDetailReducer(
                    id: id, userID: session.profile.id, resultParticipantID: resultParticipantID, routines: session.repositories.routines,
                    comments: session.repositories.comments)))
        self.onBack = onBack
        self.onDelete = onDelete
    }

    init(state: RoutineDetailReducer.State, onBack: @escaping () -> Void) {
        _store = StateObject(wrappedValue: StoreOf<RoutineDetailReducer>(state: state, reducer: RoutineDetailReducer()))
        self.onBack = onBack
        onDelete = {}
        session = nil
        routineID = nil
        onParticipationCompleted = {}
    }

    var body: some View { RoutineDetailView(store: store, session: session, routineID: routineID, onParticipationCompleted: onParticipationCompleted, onBack: onBack, onDelete: onDelete) }
}
