import RoufCore
import MVICore
import SwiftUI

struct RoutineEditView: View {
    let target: RoutineDraftSaver.EditTarget
    let onSaved: () -> Void
    let onCancel: () -> Void

    @StateObject private var store: StoreOf<RoutineCreateReducer>
    @State private var saving: Task<Void, Never>?
    @State private var feedback: FeedbackMessage?
    @State private var saver: RoutineDraftSaver

    init(
        detail: RoutineDetailEntity, target: RoutineDraftSaver.EditTarget,
        repositories: AppContainer.ProfileRepositories,
        onSaved: @escaping () -> Void, onCancel: @escaping () -> Void
    ) {
        self.target = target
        self.onSaved = onSaved
        self.onCancel = onCancel
        _saver = State(initialValue: RoutineDraftSaver(images: repositories.images, routines: repositories.routines))
        let steps = (detail.cards ?? []).map { card in
            let time = card.time.split(separator: ":")
            return RoutineCreateReducer.Step(
                photo: .stored(id: card.imageID, url: card.imageURL),
                time: TimeOfDay(hour: Int(time.first ?? "") ?? 0, minute: Int(time.dropFirst().first ?? "") ?? 0),
                title: card.title, content: card.content ?? "")
        }
        _store = StateObject(wrappedValue: StoreOf<RoutineCreateReducer>(
            state: .init(
                steps: steps, routineTitle: detail.title, routineIntroduction: detail.content ?? "",
                introductionLimit: 500),
            reducer: RoutineCreateReducer()))
    }

    private var title: String {
        switch target {
        case .routine: "루틴 수정"
        case .participation: "참여 기록 수정"
        }
    }

    var body: some View {
        RoutineCreateView(store: store, editingTitle: title) { outcome in
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
                ProgressView("변경사항을 저장하고 있어요")
                    .padding(AppSpacing.md)
                    .background(AppColor.background, in: RoundedRectangle(cornerRadius: AppRadius.button))
            }
        }
        .feedbackPopup($feedback)
        .onDisappear { saving?.cancel() }
    }

    private func save(_ draft: RoutineDraft) {
        guard saving == nil else { return }
        saving = Task {
            defer { saving = nil }
            do {
                try await saver.update(draft, target: target)
                try Task.checkCancellation()
                onSaved()
            } catch {
                if !Task.isCancelled {
                    feedback = FeedbackMessage(kind: .error, title: "변경사항을 저장하지 못했어요",
                                               message: error.localizedDescription)
                }
            }
        }
    }
}
