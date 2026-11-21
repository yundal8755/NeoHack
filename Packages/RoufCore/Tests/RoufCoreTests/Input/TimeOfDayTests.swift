import RoufCore
import Testing

@Suite("TimeOfDay")
struct TimeOfDayTests {
    @Test(arguments: [
        (0, 0, "00:00"),
        (9, 5, "09:05"),
        (23, 30, "23:30"),
    ])
    func HH_mm_형식으로_표시한다(hour: Int, minute: Int, expected: String) {
        #expect(TimeOfDay(hour: hour, minute: minute).formatted == expected)
    }

    @Test(arguments: [
        (-1, -5, 0, 0),
        (24, 60, 23, 59),
    ])
    func 범위를_벗어난_값은_경계값으로_맞춘다(hour: Int, minute: Int, expectedHour: Int, expectedMinute: Int) {
        let time = TimeOfDay(hour: hour, minute: minute)

        #expect(time.hour == expectedHour)
        #expect(time.minute == expectedMinute)
    }

    @Test(arguments: [
        (0, TimeOfDay.Period.am, 12),
        (1, .am, 1),
        (11, .am, 11),
        (12, .pm, 12),
        (13, .pm, 1),
        (23, .pm, 11),
    ])
    func 스물네시간제를_오전_오후_12시간제로_바꾼다(hour: Int, period: TimeOfDay.Period, hour12: Int) {
        let time = TimeOfDay(hour: hour, minute: 0)

        #expect(time.period == period)
        #expect(time.hour12 == hour12)
    }

    @Test(arguments: [
        (TimeOfDay.Period.am, 12, 0),
        (.am, 1, 1),
        (.am, 11, 11),
        (.pm, 12, 12),
        (.pm, 1, 13),
        (.pm, 11, 23),
    ])
    func 오전_오후_12시간제를_24시간제로_바꾼다(period: TimeOfDay.Period, hour12: Int, hour: Int) {
        #expect(TimeOfDay(period: period, hour12: hour12, minute: 0).hour == hour)
    }

    @Test(arguments: [
        (0, 0),
        (4, 0),
        (5, 5),
        (59, 55),
    ])
    func 분을_5분_단위로_내림한다(minute: Int, expected: Int) {
        #expect(TimeOfDay(hour: 10, minute: minute).flooringMinute(toMultipleOf: 5).minute == expected)
    }
}
