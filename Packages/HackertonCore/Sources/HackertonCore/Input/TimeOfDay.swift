import Foundation

/// 하루 중 시각(시·분). 루틴 스텝의 시간 입력에 쓴다.
/// 화면 표시는 24시간 `HH:mm`, 선택 시트는 오전/오후 12시간제를 쓰므로 두 표현을 변환한다.
public struct TimeOfDay: Equatable, Hashable, Sendable {
    public enum Period: String, CaseIterable, Sendable {
        case am
        case pm
    }

    /// 0...23
    public let hour: Int
    /// 0...59
    public let minute: Int

    /// 범위를 벗어난 값은 가장 가까운 경계값으로 맞춘다.
    public init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    /// 12시간제 값으로 만든다. `hour12`는 1...12이며 오전 12시는 0시, 오후 12시는 12시다.
    public init(period: Period, hour12: Int, minute: Int) {
        let hour12 = min(max(hour12, 1), 12)
        let hour = switch period {
        case .am: hour12 == 12 ? 0 : hour12
        case .pm: hour12 == 12 ? 12 : hour12 + 12
        }
        self.init(hour: hour, minute: minute)
    }

    public var period: Period {
        hour < 12 ? .am : .pm
    }

    /// 1...12
    public var hour12: Int {
        let value = hour % 12
        return value == 0 ? 12 : value
    }

    /// `HH:mm` (예: 09:05, 23:30)
    public var formatted: String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// 분을 `step` 단위로 내림한 시각. 선택 시트의 분 목록(5분 단위)에 맞출 때 쓴다.
    public func flooringMinute(toMultipleOf step: Int) -> TimeOfDay {
        guard step > 0 else { return self }
        return TimeOfDay(hour: hour, minute: minute - minute % step)
    }
}
