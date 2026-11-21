import HackertonCore
import MVICore
import SwiftUI

struct RoutineParticipationView: View {
    let routineID: String
    let repositories: AppContainer.ProfileRepositories
    let onCompleted: (RoutineInteractions) -> Void
    let onCancel: () -> Void
    let onDraftSaved: () -> Void
    private let expectedSteps: Int
    @StateObject private var store: StoreOf<RoutineCreateReducer>
    @State private var saver: RoutineDraftSaver?
    @State private var saving: Task<Void, Never>?
    @State private var hasJoined: Bool
    @State private var isRestoring = true
    @State private var restoreError: String?
    @State private var restoreAttempt = UUID()
    @State private var error: FeedbackMessage?

    init(routineID: String, steps: [RoutineDetailReducer.Step],
         participation: RoutineDetailReducer.Participation,
         repositories: AppContainer.ProfileRepositories,
         onCompleted: @escaping (RoutineInteractions) -> Void, onCancel: @escaping () -> Void,
         onDraftSaved: @escaping () -> Void) {
        self.routineID = routineID
        self.repositories = repositories
        self.onCompleted = onCompleted
        self.onCancel = onCancel
        self.onDraftSaved = onDraftSaved
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
        NavigationStack {
            Group {
                if let restoreError {
                    VStack {
                        AppTopBar("루틴 따라하기", trailing: .exit(onCancel))
                        ErrorView(title: "임시저장을 불러오지 못했어요", message: restoreError, retryTitle: "다시 시도") {
                            restoreAttempt = UUID()
                        }
                    }
                } else if isRestoring {
                    ProgressView("임시저장을 확인하고 있어요")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    RoutineCreateView(store: store, isParticipation: true, onSaveDraft: saveDraft) { outcome in
                        switch outcome {
                        case .cancelled: onCancel()
                        case let .completed(draft):
                            store.send(.outcomeHandled)
                            save(draft)
                        }
                    }
                }
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
        .task(id: restoreAttempt) { await restore() }
        .feedbackPopup($error)
        .onDisappear { saving?.cancel() }
    }

    private func restore() async {
        isRestoring = true
        restoreError = nil
        defer { isRestoring = false }
        guard hasJoined else { return }
        let saver = self.saver ?? RoutineDraftSaver(images: repositories.images, routines: repositories.routines)
        self.saver = saver
        do {
            if let draft = try await saver.restoreParticipationDraft(routineID: routineID, steps: store.state.steps) {
                try Task.checkCancellation()
                store.send(.draftRestored(steps: draft.steps, title: draft.routineTitle, introduction: draft.routineIntroduction))
            }
        } catch is CancellationError {
        } catch {
            restoreError = error.localizedDescription
        }
    }

    private func saveDraft(_ state: RoutineCreateReducer.State) {
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
                try await saver.saveParticipationDraft(state, routineID: routineID)
                try Task.checkCancellation()
                onDraftSaved()
            } catch is CancellationError {
            } catch {
                self.error = FeedbackMessage(kind: .error, title: "임시저장하지 못했어요", message: error.localizedDescription)
            }
        }
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
