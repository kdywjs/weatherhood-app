import Foundation

enum SceneRuler {
    static func windowStart(minute: Int) -> Int { min(959, max(0, minute - 240)) }
    static func minute(start: Int, fraction: Double) -> Int {
        guard fraction.isFinite else { return max(0, min(MainWeatherState.lastMinute, start)) }
        return max(0, min(MainWeatherState.lastMinute, start + Int(max(0, min(1, fraction)) * 480)))
    }
}

/// Design previews only; these cases do not establish production weather thresholds.
enum WeatherScene: String, CaseIterable, Identifiable, Sendable {
    case sunny, cloudy, rain, snow, hot, cold, wind, storm, dawn, sunset, night, rainNight
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sunny: "맑음"
        case .cloudy: "흐림"
        case .rain: "비"
        case .snow: "눈"
        case .hot: "더위"
        case .cold: "추위"
        case .wind: "바람"
        case .night: "맑은 밤"
        case .storm: "천둥번개"
        case .dawn: "일출"
        case .sunset: "노을"
        case .rainNight: "비 오는 밤"
        }
    }
    var asset: String { "Urban" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
    var isDark: Bool { self == .night || self == .rainNight || self == .storm }
    var previewMinute: Int {
        switch self {
        case .dawn: 6 * 60
        case .sunset: 17 * 60 + 30
        case .night: 21 * 60
        case .rainNight: 22 * 60
        default: 15 * 60
        }
    }
    var symbol: String {
        switch self {
        case .sunny, .hot: "sun.max"
        case .cloudy: "cloud"
        case .rain, .rainNight: "cloud.rain"
        case .storm: "cloud.bolt.rain"
        case .dawn: "sunrise"
        case .sunset: "sunset"
        case .snow, .cold: "snowflake"
        case .wind: "wind"
        case .night: "moon.stars"
        }
    }
    var sampleTemperature: Int {
        switch self {
        case .sunny: 24
        case .cloudy: 19
        case .rain: 16
        case .snow: -2
        case .hot: 32
        case .cold: -8
        case .wind: 15
        case .night: 12
        case .storm: 17
        case .dawn: 12
        case .sunset: 18
        case .rainNight: 14
        }
    }
    static func forecast(_ condition: WeatherCondition, minute: Int) -> Self {
        switch condition {
        case .rainy, .rainAndWind: minute < 360 || minute >= 1080 ? .rainNight : .rain
        case .cloudy: .cloudy
        case .sunny:
            // Fixed demo windows, not real local sunrise/sunset calculations.
            switch minute {
            case 360..<420: .dawn
            case 420..<1020: .sunny
            case 1020..<1080: .sunset
            default: .night
            }
        }
    }
}

enum WeatherCondition: String, Sendable {
    case cloudy, sunny, rainy, rainAndWind

    var title: String {
        switch self {
        case .cloudy: "흐림"
        case .sunny: "맑음"
        case .rainy: "비"
        case .rainAndWind: "비 · 바람"
        }
    }

    func asset(selected: Bool = false) -> String {
        switch self {
        case .cloudy: "Cloud"
        case .sunny: "Sun"
        case .rainy: selected ? "RainSelected" : "Rain"
        case .rainAndWind: selected ? "RainWindSelected" : "Rain"
        }
    }
}

struct HourForecast: Identifiable, Sendable {
    let hour: Int
    let temperature: Int
    let condition: WeatherCondition
    var id: Int { hour }
}

struct DayForecast: Identifiable, Sendable {
    let id: Int
    let day: Int
    let weekday: String
    let low: Int
    let high: Int
    let condition: WeatherCondition
    let hours: [HourForecast]
    var dateLabel: String { "10.\(day)" }
    var shortLabel: String { id == 0 ? "오늘" : weekday }
}

/// 고정 시계와 가상 예보를 사용하는 UI 데모. 실제 날씨나 공급처 계약이 아닙니다.
struct MainWeatherState {
    static let demoNowMinute = 15 * 60
    static let lastMinute = 23 * 60 + 59
    static let sampleHours = [0, 3, 6, 9, 12, 15, 18, 21, 23]

    let days: [DayForecast]
    private(set) var selectedDayIndex = 0
    private(set) var minute = Self.demoNowMinute
    private(set) var isPlaying = false

    init() {
        let weekdays = ["토", "일", "월", "화", "수", "목", "금"]
        let lows = [10, 12, 11, 12, 13, 11, 10]
        let highs = [18, 20, 21, 22, 19, 20, 21]
        let conditions: [WeatherCondition] = [.rainy, .cloudy, .sunny, .sunny, .rainy, .cloudy, .sunny]
        days = (0..<7).map { index in
            let temperatures = index == 0
                ? [14, 13, 12, 18, 16, 12, 11, 10, 10]
                : [lows[index] + 2, lows[index], lows[index] + 1, highs[index] - 2,
                   highs[index], highs[index] - 2, lows[index] + 3, lows[index] + 1, lows[index]]
            let hours = Self.sampleHours.enumerated().map { offset, hour in
                let condition: WeatherCondition = index == 0
                    ? (hour == 15 ? .rainAndWind : hour == 18 ? .rainy : .cloudy)
                    : conditions[index]
                return HourForecast(hour: hour, temperature: temperatures[offset], condition: condition)
            }
            return DayForecast(id: index, day: 10 + index, weekday: weekdays[index],
                               low: lows[index], high: highs[index], condition: conditions[index], hours: hours)
        }
    }

    var selectedDay: DayForecast { days[selectedDayIndex] }
    var selectedForecast: HourForecast {
        selectedDay.hours.last(where: { $0.hour * 60 <= minute }) ?? selectedDay.hours[0]
    }
    var timeLabel: String { String(format: "%02d:%02d", minute / 60, minute % 60) }
    var dateTimeLabel: String { "\(selectedDay.dateLabel) \(selectedDay.weekday) · \(timeLabel)" }

    mutating func selectDay(_ index: Int) {
        guard days.indices.contains(index) else { return }
        guard index != selectedDayIndex else { return }
        selectedDayIndex = index
        minute = index == 0 ? Self.demoNowMinute : 0
        isPlaying = false
    }

    mutating func selectHour(_ hour: Int) {
        guard selectedDay.hours.contains(where: { $0.hour == hour }) else { return }
        minute = hour * 60
        isPlaying = minute < Self.lastMinute
    }

    mutating func scrub(to value: Double) {
        guard value.isFinite else { return }
        minute = Int(min(Double(Self.lastMinute), max(0, value)).rounded())
        isPlaying = false
    }

    mutating func togglePlayback() {
        guard minute < Self.lastMinute else {
            isPlaying = false
            return
        }
        isPlaying.toggle()
    }

    mutating func advance(minutes: Int = 60) {
        guard isPlaying, minutes > 0 else { return }
        minute = min(Self.lastMinute, minute + min(minutes, Self.lastMinute))
        if minute == Self.lastMinute { isPlaying = false }
    }

    mutating func pause() { isPlaying = false }

    mutating func resetToCurrent() {
        selectedDayIndex = 0
        minute = Self.demoNowMinute
        isPlaying = false
    }
}
