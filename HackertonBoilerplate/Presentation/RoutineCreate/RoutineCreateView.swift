import HackertonCore
import MVICore
import PhotosUI
import SwiftUI

/// 루틴 작성 화면. Figma `루틴 만들기` 프레임(스텝 작성 / 루틴 소개).
/// 작성을 마치거나 나가면 `onFinish`로 결과를 알린다.
struct RoutineCreateView: View {
    typealias Feature = RoutineCreateReducer

    @StateObject private var store: StoreOf<Feature>
    private let onFinish: (Feature.Outcome) -> Void

    @State private var replacingImageItem: PhotosPickerItem?

    init(store: StoreOf<Feature>, onFinish: @escaping (Feature.Outcome) -> Void = { _ in }) {
        _store = StateObject(wrappedValue: store)
        self.onFinish = onFinish
    }

    private var state: Feature.State { store.state }

    var body: some View {
        VStack(spacing: 0) {
            AppTopBar("루틴 만들기", trailing: .exit { store.send(.exitTapped) })

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
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomButtons
            }
        }
        .background(AppColor.background)
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
                RoutineImageView(image: step.image)
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "스텝 이미지"))
            .accessibilityHint(Text(verbatim: "다른 이미지로 바꿉니다"))
            .accessibilityIdentifier(AccessibilityID.RoutineCreate.stepImage)

            HStack(spacing: AppSpacing.inlineLabelGap) {
                FieldTitle("시간", isRequired: true)
                TimeChip(time: step.time) { store.send(.timeTapped) }
                    .accessibilityIdentifier(AccessibilityID.RoutineCreate.timeChip)
            }

            FormField("제목", guide: "5자에서 30자까지 입력해 주세요.", isRequired: true) {
                AppTextField(
                    "5자에서 30자까지 입력해 주세요.",
                    text: Binding(get: { step.title }, set: { store.send(.stepTitleChanged($0)) }),
                    maxLength: Feature.stepTitleLength.upperBound
                )
                .accessibilityIdentifier(AccessibilityID.RoutineCreate.stepTitleField)
            }

            FormField("내용", guide: "최대 100자까지 입력 가능합니다.") {
                AppTextField(
                    "최대 100자까지 입력 가능합니다.",
                    text: Binding(get: { step.content }, set: { store.send(.stepContentChanged($0)) }),
                    axis: .vertical,
                    maxLength: Feature.stepContentMaxLength
                )
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
                .accessibilityIdentifier(AccessibilityID.RoutineCreate.routineTitleField)
            }

            FormField("루틴 소개", guide: "최대 100자까지 입력 가능해요.") {
                AppTextField(
                    "나의 루틴을 소개해 주세요.",
                    text: Binding(
                        get: { state.routineIntroduction },
                        set: { store.send(.routineIntroductionChanged($0)) }
                    ),
                    axis: .vertical,
                    maxLength: Feature.routineIntroductionMaxLength
                )
                .accessibilityIdentifier(AccessibilityID.RoutineCreate.routineIntroductionField)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - 하단 버튼

    /// 첫 스텝에서는 이전 버튼 자리를 비워 다음 버튼을 오른쪽 절반에 둔다(Figma 첫 스텝 프레임).
    private var bottomButtons: some View {
        HStack(spacing: AppSpacing.buttonPadding) {
            PrimaryButton("이전") { store.send(.previousTapped) }
                .opacity(state.isPreviousVisible ? 1 : 0)
                .disabled(!state.isPreviousVisible)
                .accessibilityHidden(!state.isPreviousVisible)
                .accessibilityIdentifier(AccessibilityID.RoutineCreate.previousButton)

            if state.currentStep != nil {
                PrimaryButton("다음") { store.send(.nextTapped) }
                    .disabled(!state.isNextEnabled)
                    .accessibilityIdentifier(AccessibilityID.RoutineCreate.nextButton)
            } else {
                PrimaryButton("완료") { store.send(.completeTapped) }
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
        Task {
            defer { replacingImageItem = nil }
            do {
                guard
                    let data = try await item.loadTransferable(type: Data.self),
                    let resized = await Self.resize(data)
                else { return }
                store.send(.stepImageReplaced(RoutineImage(data: resized)))
            } catch {
                AppLogger.error("스텝 이미지를 불러오지 못했어요: \(error)")
            }
        }
    }

    private static func resize(_ data: Data) async -> Data? {
        let maxPixelSize = RoutineImageView.maxPixelSize
        return await Task.detached(priority: .userInitiated) {
            ImageDownsampler.downsampledJPEGData(from: data, maxPixelSize: maxPixelSize)
        }.value
    }

    /// Figma 이미지 영역 높이.
    static let imageHeight: CGFloat = 340
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
