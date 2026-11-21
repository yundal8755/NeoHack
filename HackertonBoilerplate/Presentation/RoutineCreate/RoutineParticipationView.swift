import HackertonCore
import MVICore
import SwiftUI

struct RoutineParticipationView: View {
    let routineID: String
    let repositories: AppContainer.ProfileRepositories
    let onCompleted: (RoutineInteractions) -> Void
    let onCancel: () -> Void
    private let expectedSteps: Int
    @StateObject private var store: StoreOf<RoutineCreateReducer>
    @State private var saver: RoutineDraftSaver?
    @State private var saving: Task<Void, Never>?
    @State private var hasJoined: Bool
    @State private var error: FeedbackMessage?

    init(routineID: String, steps: [RoutineDetailReducer.Step],
         participation: RoutineDetailReducer.Participation,
         repositories: AppContainer.ProfileRepositories,
         onCompleted: @escaping (RoutineInteractions) -> Void, onCancel: @escaping () -> Void) {
        self.routineID = routineID
        self.repositories = repositories
        self.onCompleted = onCompleted
        self.onCancel = onCancel
        expectedSteps = steps.count
        _hasJoined = State(initialValue: participation == .joined)
        let forms = steps.map { reference in
            let parts = reference.time.split(separator: ":").compactMap { Int($0) }
            return RoutineCreateReducer.Step(
                photo: .reference(reference.imageURL),
                time: TimeOfDay(hour: parts.first ?? 0, minute: parts.dropFirst().first ?? 0))
        }
        _store = StateObject(wrappedValue: StoreOf<RoutineCreateReducer>(
            state: .init(steps: forms), reducer: RoutineCreateReducer()))
    }

    var body: some View {
        RoutineCreateView(store: store, isParticipation: true) { outcome in
            switch outcome {
            case .cancelled: onCancel()
            case let .completed(draft):
                store.send(.outcomeHandled)
                save(draft)
            }
        }
        .disabled(saving != nil)
        .interactiveDismissDisabled(saving != nil)
        .overlay {
            if saving != nil {
                ProgressView("참여 기록을 저장하고 있어요")
                    .padding(AppSpacing.md)
                    .background(AppColor.background, in: RoundedRectangle(cornerRadius: AppRadius.button))
            }
        }
        .feedbackPopup($error)
        .onDisappear { saving?.cancel() }
    }

    private func save(_ draft: RoutineDraft) {
        guard saving == nil else { return }
        let saver = self.saver ?? RoutineDraftSaver(images: repositories.images, routines: repositories.routines)
        self.saver = saver
        saving = Task {
            defer { saving = nil }
            do {
                if !hasJoined {
                    _ = try await repositories.routines.interactions(id: routineID, change: .join)
                    hasJoined = true
                }
                let result = try await saver.saveParticipation(draft, routineID: routineID, expectedSteps: expectedSteps)
                try Task.checkCancellation()
                onCompleted(result)
            } catch is CancellationError {
                // The user left the screen; retain the server's current participation state.
            } catch {
                self.error = FeedbackMessage(kind: .error, title: "참여 기록을 저장하지 못했어요", message: error.localizedDescription)
            }
        }
    }
}
