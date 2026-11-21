import HackertonCore
import SnapshotTesting
import SwiftUI
import Testing
@testable import HackertonBoilerplate

/// 공통 컴포넌트가 깨지지 않는지 확인한다.
/// 기준 이미지는 __Snapshots__에 있고, 없으면 첫 실행에서 기록한 뒤 실패한다(다시 실행하면 통과).
@MainActor
@Suite(.snapshots(record: .missing))
struct ComponentSnapshotTests {
    @Test func loadingView() {
        assertSnapshot(of: LoadingView().snapshotContainer(), as: .component)
    }

    @Test func emptyView() {
        let view = HackertonBoilerplate.EmptyView(title: "아직 내용이 없어요", message: "새 항목을 추가하면 여기에 보여요.")
        assertSnapshot(of: view.snapshotContainer(), as: .component)
    }

    @Test(arguments: [true, false])
    func errorView(hasRetry: Bool) {
        let view = ErrorView(message: "잠시 후 다시 시도해 주세요.", retry: hasRetry ? {} : nil)
        assertSnapshot(of: view.snapshotContainer(), as: .component, named: hasRetry ? "retry" : "noRetry")
    }

    @Test(arguments: [nil, "arrow.right"] as [String?])
    func primaryButton(systemImage: String?) {
        let view = PrimaryButton("계속하기", systemImage: systemImage) {}
        assertSnapshot(of: view.snapshotContainer(), as: .component, named: systemImage == nil ? "text" : "icon")
    }

    @Test func primaryButtonDisabled() {
        let view = PrimaryButton("다음") {}
            .disabled(true)
        assertSnapshot(of: view.snapshotContainer(), as: .component)
    }

    @Test func primaryButtonSecondary() {
        let view = PrimaryButton("취소", style: .secondary) {}
        assertSnapshot(of: view.snapshotContainer(), as: .component)
    }

    @Test(arguments: ["empty", "filled", "multiline"])
    func appTextField(state: String) {
        let view: AppTextField = switch state {
        case "empty":
            AppTextField("5자에서 30자까지 입력해 주세요.", text: .constant(""))
        case "filled":
            AppTextField("5자에서 30자까지 입력해 주세요.", text: .constant("아침에 지하철 타러 가요."))
        default:
            AppTextField(
                "최대 100자까지 입력 가능합니다.",
                text: .constant("아침에 역시나 사람이 많아요. 지하철 사람들이 모두 회색 인간인 것 같아요. 출근할 때 항상 타는 것인데, 먼가 우울하게 시작하는 것 같아요."),
                axis: .vertical
            )
        }
        assertSnapshot(of: view.snapshotContainer(), as: .component, named: state)
    }

    @Test(arguments: ["home", "detail", "createRoutine", "routineDetail"])
    func appTopBar(variant: String) {
        let view: AppTopBar = switch variant {
        case "home": AppTopBar("서비스명", leading: .add {}, trailing: .profile {})
        case "detail": AppTopBar("서비스명", leading: .back {})
        case "createRoutine": AppTopBar("루틴 만들기", trailing: .exit {})
        default: AppTopBar("김햄찌의 하루", leading: .back {}, trailing: .more {})
        }
        assertSnapshot(of: view.snapshotContainer(), as: .component, named: variant)
    }

    @Test(arguments: [1, 2, 5])
    func stepIndicator(current: Int) {
        let view = StepIndicator(count: 4, current: current)
        assertSnapshot(of: view.snapshotContainer(), as: .component, named: "current\(current)")
    }

    @Test(arguments: [true, false])
    func formField(isRequired: Bool) {
        let view = FormField("루틴 제목", guide: "5자에서 30자까지 입력해 주세요.", isRequired: isRequired) {
            AppTextField("루틴을 대표하는 제목을 입력해 주세요.", text: .constant(""))
        }
        assertSnapshot(of: view.snapshotContainer(), as: .component, named: isRequired ? "required" : "optional")
    }

    @Test func timeChip() {
        let view = HStack(spacing: AppSpacing.inlineLabelGap) {
            FieldTitle("시간", isRequired: true)
            TimeChip(time: TimeOfDay(hour: 10, minute: 30)) {}
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        assertSnapshot(of: view.snapshotContainer(), as: .component)
    }

    @Test func timePickerSheet() {
        let view = TimePickerSheet(time: TimeOfDay(hour: 22, minute: 33), onCancel: {}, onConfirm: { _ in })
            .frame(height: TimePickerSheet.sheetHeight, alignment: .top)
        assertSnapshot(of: view.snapshotContainer(width: 402), as: .component)
    }
}
