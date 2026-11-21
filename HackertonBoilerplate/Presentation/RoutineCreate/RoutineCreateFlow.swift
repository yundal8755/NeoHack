import HackertonCore
import MVICore
import PhotosUI
import SwiftUI

extension View {
    /// 루틴 만들기 흐름: 사진을 최대 4장 고르면 고른 순서대로 스텝을 만들어 루틴 작성 화면을 띄운다.
    /// 각 스텝의 시간은 사진 촬영 시각(없으면 지금)을 5분 단위로 내려 미리 채운다.
    func routineCreateFlow(
        isPickingImages: Binding<Bool>,
        repositories: AppContainer.ProfileRepositories?,
        onCreated: @escaping (String) -> Void
    ) -> some View {
        modifier(RoutineCreateFlow(isPresented: isPickingImages, repositories: repositories, onCreated: onCreated))
    }
}

private struct RoutineCreateFlow: ViewModifier {
    @Binding var isPresented: Bool

    let repositories: AppContainer.ProfileRepositories?
    let onCreated: (String) -> Void

    @State private var feedback: FeedbackMessage?
    @State private var createdID: String?

    func body(content: Content) -> some View {
        content
            // 사진 선택 시트를 먼저 띄운 뒤 전체 화면을 띄우면 전체 화면의 safe area가 0이 되어
            // 상단바가 상태 표시줄 아래로 들어간다(iOS 26.2). 전체 화면을 먼저 띄우고 그 안에서 사진을 고른다.
            .fullScreenCover(isPresented: $isPresented, onDismiss: {
                if let createdID {
                    onCreated(createdID)
                    self.createdID = nil
                }
            }) {
                RoutineCreateEntry(repositories: repositories, onFinish: finish)
            }
            .feedbackPopup($feedback)
    }

    private func finish(_ result: RoutineCreateEntry.Result) {
        switch result {
        case .cancelled:
            break
        case .failedToLoad:
            feedback = FeedbackMessage(kind: .error, title: "사진을 불러오지 못했어요", message: "다른 사진을 골라 주세요.")
        case let .created(id):
            createdID = id
        }
        isPresented = false
    }
}

/// 전체 화면 안에서 사진 선택 → 루틴 작성 화면으로 이어지는 진입 화면.
private struct RoutineCreateEntry: View {
    enum Result {
        case cancelled
        case failedToLoad
        case created(String)
    }

    let repositories: AppContainer.ProfileRepositories?
    let onFinish: (Result) -> Void

    @State private var saver: RoutineDraftSaver?
    @State private var saving: Task<Void, Never>?
    @State private var saveError: FeedbackMessage?

    @State private var isPickerPresented = false
    @State private var selection: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var store: StoreOf<RoutineCreateReducer>?

    var body: some View {
        Group {
            if let store {
                RoutineCreateView(store: store) { outcome in
                    switch outcome {
                    case .cancelled: onFinish(.cancelled)
                    case let .completed(draft):
                        store.send(.outcomeHandled)
                        save(draft)
                    }
                }
            } else {
                AppColor.background
                    .ignoresSafeArea()
                    .overlay {
                        if isLoading { ProgressView() }
                    }
                    .accessibilityIdentifier(AccessibilityID.RoutineCreate.entry)
            }
        }
        .disabled(saving != nil)
        .interactiveDismissDisabled(saving != nil)
        .overlay { if saving != nil { ProgressView("루틴을 저장하고 있어요").padding().background(.regularMaterial) } }
        .feedbackPopup($saveError)
        .onDisappear { saving?.cancel() }
        .photosPicker(
            isPresented: $isPickerPresented,
            selection: $selection,
            maxSelectionCount: RoutineCreateReducer.maxStepCount,
            selectionBehavior: .ordered,
            matching: .images,
            photoLibrary: .shared()
        )
        .onAppear {
            if store == nil { isPickerPresented = true }
        }
        .onChange(of: selection) { _, items in
            guard !items.isEmpty else { return }
            load(items)
        }
        .onChange(of: isPickerPresented) { _, presented in
            guard !presented else { return }
            // 선택 완료 시 selection 변경이 닫힘보다 늦게 올 수 있어 잠시 기다린 뒤 취소 여부를 판단한다.
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                if selection.isEmpty, !isLoading, store == nil {
                    onFinish(.cancelled)
                }
            }
        }
    }

    private func save(_ draft: RoutineDraft) {
        guard saving == nil, let repositories else { return }
        let saver = self.saver ?? RoutineDraftSaver(images: repositories.images, routines: repositories.routines)
        self.saver = saver
        saving = Task {
            defer { saving = nil }
            do {
                let detail = try await saver.save(draft)
                if !Task.isCancelled { onFinish(.created(detail.id)) }
            } catch {
                if !Task.isCancelled {
                    saveError = FeedbackMessage(kind: .error, title: "루틴을 저장하지 못했어요",
                                                message: error.localizedDescription)
                }
            }
        }
    }

    private func load(_ items: [PhotosPickerItem]) {
        isLoading = true
        Task {
            let steps = await Self.makeSteps(from: items)
            isLoading = false
            guard !steps.isEmpty else {
                onFinish(.failedToLoad)
                return
            }
            store = StoreOf<RoutineCreateReducer>(state: .init(steps: steps), reducer: RoutineCreateReducer())
        }
    }

    private static func makeSteps(from items: [PhotosPickerItem]) async -> [RoutineCreateReducer.Step] {
        var steps: [RoutineCreateReducer.Step] = []
        let maxPixelSize = RoutineImageView.maxPixelSize
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let (resized, capturedAt) = await Task.detached(priority: .userInitiated) {
                    (
                        ImageDownsampler.downsampledJPEGData(from: data, maxPixelSize: maxPixelSize),
                        ImageDownsampler.capturedDate(of: data)
                    )
                }.value
                guard let resized else { continue }

                steps.append(RoutineCreateReducer.Step(
                    image: RoutineImage(data: resized),
                    time: timeOfDay(from: capturedAt ?? Date())
                ))
            } catch {
                AppLogger.error("루틴 사진을 불러오지 못했어요: \(error)")
            }
        }
        return steps
    }

    private static func timeOfDay(from date: Date) -> TimeOfDay {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return TimeOfDay(hour: components.hour ?? 0, minute: components.minute ?? 0)
            .flooringMinute(toMultipleOf: TimePickerSheet.minuteStep)
    }
}
