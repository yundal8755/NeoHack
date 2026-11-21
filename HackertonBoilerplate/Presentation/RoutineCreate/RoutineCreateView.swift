import HackertonCore
import MVICore
import PhotosUI
import SwiftUI

/// 루틴 작성 화면. Figma `루틴 만들기` 프레임(스텝 작성 / 루틴 소개).
/// 작성을 마치거나 나가면 `onFinish`로 결과를 알린다.
struct RoutineCreateView: View {
    typealias Feature = RoutineCreateReducer

    @StateObject private var store: StoreOf<Feature>
    private let isParticipation: Bool
    private let title: String
    private let submitTitle: String
    private let onFinish: (Feature.Outcome) -> Void

    @State private var imageError: FeedbackMessage?
    @State private var photoTask: Task<Void, Never>?
    @State private var replacingImageItem: PhotosPickerItem?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case stepTitle
        case stepContent
        case routineTitle
        case routineIntroduction
    }

    init(
        store: StoreOf<Feature>, isParticipation: Bool = false, editingTitle: String? = nil,
        onFinish: @escaping (Feature.Outcome) -> Void = { _ in }
    ) {
        _store = StateObject(wrappedValue: store)
        self.onFinish = onFinish
        self.isParticipation = isParticipation
        title = editingTitle ?? (isParticipation ? "루틴 따라하기" : "루틴 만들기")
        submitTitle = editingTitle == nil ? "완료" : "저장"
    }

    private var state: Feature.State { store.state }

    var body: some View {
        // 스크롤 영역만 키보드를 피하고, 하단 버튼은 키보드를 따라 올라오지 않도록 키보드 영역을 무시한다.
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AppTopBar(title, trailing: .exit { store.send(.exitTapped) })

                ScrollView {
                    VStack(spacing: 0) {
                        StepIndicator(count: state.steps.count, current: state.indicatorStep)

                        if let step = state.currentStep {
                            stepForm(step)
                                .id(step.id)
                        } else {
                            introductionForm
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .background {
                        // 입력창 밖 빈 곳을 누르면 키보드를 내린다.
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { focusedField = nil }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                // 키보드가 없을 때 마지막 입력창이 하단 버튼에 가리지 않도록 버튼 높이만큼 비워 둔다.
                .safeAreaPadding(.bottom, Self.bottomBarHeight)
            }

            bottomButtons
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .background(AppColor.background)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    focusedField = nil
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                .accessibilityLabel(Text(verbatim: "키보드 내리기"))
                .accessibilityIdentifier(AccessibilityID.RoutineCreate.dismissKeyboardButton)
            }
        }
        .feedbackPopup($imageError)
        .onDisappear { photoTask?.cancel() }
        .onChange(of: state.page) { _, _ in
            focusedField = nil
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier(AccessibilityID.RoutineCreate.screen)
        .alert(
            Text(verbatim: "루틴 작성을 정말로 취소하시겠습니까?"),
            isPresented: Binding(
                get: { state.isExitAlertPresented },
                set: { if !$0 { store.send(.exitCancelled) } }
            )
        ) {
            Button(role: .cancel) { store.send(.exitCancelled) } label: { Text(verbatim: "취소") }
            Button(role: .destructive) { store.send(.exitConfirmed) } label: { Text(verbatim: "확인") }
        }
        .timePickerSheet(
            isPresented: Binding(
                get: { state.isTimePickerPresented },
                set: { if !$0 { store.send(.timePickerDismissed) } }
            ),
            time: Binding(
                get: { state.currentStep?.time ?? TimeOfDay(hour: 0, minute: 0) },
                set: { store.send(.timeSelected($0)) }
            )
        )
        .onChange(of: replacingImageItem) { _, item in
            guard let item else { return }
            replaceImage(with: item)
        }
        .onChange(of: state.outcome) { _, outcome in
            if let outcome { onFinish(outcome) }
        }
    }

    // MARK: - 스텝 작성

    private func stepForm(_ step: Feature.Step) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            PhotosPicker(selection: $replacingImageItem, matching: .images, photoLibrary: .shared()) {
                ZStack {
                    switch step.photo {
                    case let .reference(url):
                        NetworkImageView(url: url, borderColor: nil, showsLoadingText: false)
                            .opacity(0.25)
                        VStack(spacing: AppSpacing.xs) {
                            Image(systemName: "camera.fill").font(.title2)
                            Text("내 사진을 올려주세요").appFont(AppFont.body2)
                            Text("배경 사진은 참고용이에요").appFont(AppFont.caption1)
                        }
                        .foregroundStyle(AppColor.textPrimary)
                    case let .stored(_, url):
                        NetworkImageView(
                            url: url, downsamplingSize: CGSize(width: 600, height: 338),
                            borderColor: nil, showsLoadingText: false)
                    case let .local(image):
                        RoutineImageView(image: image)
                    }
                }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "스텝 이미지"))
            .accessibilityHint(Text(verbatim: step.requiresImageUpload ? "내 사진을 필수로 선택합니다" : "다른 이미지로 바꿉니다"))
            .accessibilityIdentifier(AccessibilityID.RoutineCreate.stepImage)

            HStack(spacing: AppSpacing.inlineLabelGap) {
                FieldTitle("시간", isRequired: true)
                TimeChip(time: step.time) {
                    focusedField = nil
                    store.send(.timeTapped)
                }
                    .accessibilityIdentifier(AccessibilityID.RoutineCreate.timeChip)
            }

            FormField("제목", guide: "5자에서 30자까지 입력해 주세요.", isRequired: true) {
                AppTextField(
                    "5자에서 30자까지 입력해 주세요.",
                    text: Binding(get: { step.title }, set: { store.send(.stepTitleChanged($0)) }),
                    maxLength: Feature.stepTitleLength.upperBound
                )
                .focused($focusedField, equals: .stepTitle)
                .accessibilityIdentifier(AccessibilityID.RoutineCreate.stepTitleField)
            }

            FormField("내용", guide: "최대 100자까지 입력 가능합니다.") {
                AppTextField(
                    "최대 100자까지 입력 가능합니다.",
                    text: Binding(get: { step.content }, set: { store.send(.stepContentChanged($0)) }),
                    axis: .vertical,
                    maxLength: Feature.stepContentMaxLength
                )
                .focused($focusedField, equals: .stepContent)
                .accessibilityIdentifier(AccessibilityID.RoutineCreate.stepContentField)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - 루틴 소개

    private var introductionForm: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            FormField("루틴 제목", guide: "5자에서 30자까지 입력해 주세요.", isRequired: true) {
                AppTextField(
                    "루틴을 대표하는 제목을 입력해 주세요.",
                    text: Binding(get: { state.routineTitle }, set: { store.send(.routineTitleChanged($0)) }),
                    maxLength: Feature.routineTitleLength.upperBound
                )
                .focused($focusedField, equals: .routineTitle)
                .accessibilityIdentifier(AccessibilityID.RoutineCreate.routineTitleField)
            }

            FormField("루틴 소개", guide: "최대 \(state.introductionLimit)자까지 입력 가능해요.") {
                AppTextField(
                    "나의 루틴을 소개해 주세요.",
                    text: Binding(
                        get: { state.routineIntroduction },
                        set: { store.send(.routineIntroductionChanged($0)) }
                    ),
                    axis: .vertical,
                    maxLength: state.introductionLimit
                )
                .focused($focusedField, equals: .routineIntroduction)
                .accessibilityIdentifier(AccessibilityID.RoutineCreate.routineIntroductionField)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - 하단 버튼

    /// 첫 스텝에서는 이전 버튼 없이 다음 버튼을 최대 너비로 둔다(Figma 첫 스텝 프레임).
    private var bottomButtons: some View {
        HStack(spacing: AppSpacing.buttonPadding) {
            if state.isPreviousVisible {
                PrimaryButton("이전") { store.send(.previousTapped) }
                    .accessibilityIdentifier(AccessibilityID.RoutineCreate.previousButton)
            }

            if state.currentStep != nil {
                PrimaryButton("다음") { store.send(.nextTapped) }
                    .disabled(!state.isNextEnabled)
                    .accessibilityIdentifier(AccessibilityID.RoutineCreate.nextButton)
            } else {
                PrimaryButton(submitTitle) { store.send(.completeTapped) }
                    .disabled(!state.isCompleteEnabled)
                    .accessibilityIdentifier(AccessibilityID.RoutineCreate.completeButton)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
        .background(AppColor.background)
    }

    // MARK: - 이미지 교체

    private func replaceImage(with item: PhotosPickerItem) {
        guard let stepID = state.currentStep?.id else { return }
        photoTask?.cancel()
        photoTask = Task {
            defer { if !Task.isCancelled { replacingImageItem = nil } }
            do {
                guard
                    let data = try await item.loadTransferable(type: Data.self),
                    let resized = await Self.resize(data)
                else {
                    if !Task.isCancelled {
                        imageError = FeedbackMessage(kind: .error, title: "사진을 불러오지 못했어요", message: "다른 사진을 선택해 주세요.")
                    }
                    return
                }
                var time: TimeOfDay?
                if isParticipation {
                    let capturedAt = await Task.detached(priority: .userInitiated) {
                        ImageDownsampler.capturedDate(of: data)
                    }.value
                    time = Self.timeOfDay(from: capturedAt ?? Date())
                }
                try Task.checkCancellation()
                store.send(.stepPhotoLoaded(id: stepID, image: RoutineImage(data: resized), time: time))
            } catch {
                if !Task.isCancelled {
                    imageError = FeedbackMessage(kind: .error, title: "사진을 불러오지 못했어요", message: "다시 선택해 주세요.")
                    AppLogger.error("스텝 이미지를 불러오지 못했어요: \(error)")
                }
            }
        }
    }

    static func timeOfDay(from date: Date) -> TimeOfDay {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return TimeOfDay(hour: components.hour ?? 0, minute: components.minute ?? 0)
            .flooringMinute(toMultipleOf: TimePickerSheet.minuteStep)
    }

    private static func resize(_ data: Data) async -> Data? {
        let maxPixelSize = RoutineImageView.maxPixelSize
        return await Task.detached(priority: .userInitiated) {
            ImageDownsampler.downsampledJPEGData(from: data, maxPixelSize: maxPixelSize)
        }.value
    }

    /// Figma 이미지 영역 높이.
    static let imageHeight: CGFloat = 340
    /// 하단 버튼 영역 높이(위 여백 + 버튼).
    private static let bottomBarHeight: CGFloat =
        AppSpacing.xs + AppFont.body2.lineHeight + AppSpacing.buttonPadding * 2
}

/// 고른 이미지를 영역에 꽉 채워 보여준다. 이미지가 바뀔 때만 다시 디코딩한다.
struct RoutineImageView: View {
    let image: RoutineImage

    @State private var uiImage: UIImage?

    /// 저장·표시에 쓰는 긴 변 픽셀 수. 이미지 영역(370pt × 3배)에 맞춘다.
    static let maxPixelSize: CGFloat = 1110

    var body: some View {
        Rectangle()
            .fill(AppColor.gray700)
            .overlay {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .task(id: image.id) {
                uiImage = await Self.decode(image.data)
            }
    }

    private static func decode(_ data: Data) async -> UIImage? {
        let maxPixelSize = maxPixelSize
        return await Task.detached(priority: .userInitiated) {
            ImageDownsampler.image(from: data, maxPixelSize: maxPixelSize)
        }.value
    }
}

#Preview("스텝") {
    RoutineCreateView(store: StoreOf<RoutineCreateReducer>(
        state: .init(steps: RoutineCreatePreview.steps),
        reducer: RoutineCreateReducer()
    ))
}

#Preview("루틴 소개") {
    RoutineCreateView(store: StoreOf<RoutineCreateReducer>(
        state: .init(steps: RoutineCreatePreview.steps, page: .introduction),
        reducer: RoutineCreateReducer()
    ))
}

enum RoutineCreatePreview {
    static let steps: [RoutineCreateReducer.Step] = (0..<4).map { _ in
        RoutineCreateReducer.Step(image: RoutineImage(data: Data()), time: TimeOfDay(hour: 10, minute: 30))
    }
}
