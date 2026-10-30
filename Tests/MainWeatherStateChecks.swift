import Foundation

@main
struct MainWeatherStateChecks {
    static func main() {
        var state = MainWeatherState()
        precondition(state.dateTimeLabel == "10.10 토 · 15:00")
        precondition(state.selectedForecast.temperature == 12)
        precondition(state.selectedForecast.condition == .rainAndWind)
        precondition(!state.isPlaying)
        state.selectHour(9)
        precondition(state.minute == 540 && state.isPlaying)
        state.advance()
        precondition(state.minute == 600)
        state.scrub(to: 720)
        precondition(state.minute == 720 && !state.isPlaying)
        state.selectDay(1)
        precondition(state.minute == 0 && !state.isPlaying)
        state.selectDay(-1)
        precondition(state.selectedDayIndex == 1)
        state.selectDay(7)
        precondition(state.selectedDayIndex == 1)
        state.scrub(to: 1430)
        state.togglePlayback()
        state.advance()
        precondition(state.minute == 1439 && !state.isPlaying)
        state.togglePlayback()
        precondition(!state.isPlaying)
        state.resetToCurrent()
        precondition(state.selectedDayIndex == 0 && state.minute == 900 && !state.isPlaying)
        state.scrub(to: -10)
        precondition(state.minute == 0)
        state.scrub(to: .infinity)
        precondition(state.minute == 0)
        state.scrub(to: .greatestFiniteMagnitude)
        precondition(state.minute == MainWeatherState.lastMinute)
        state.scrub(to: -.greatestFiniteMagnitude)
        precondition(state.minute == 0)
        state.scrub(to: .nan)
        precondition(state.minute == 0)
        state.selectHour(15)
        state.pause()
        state.advance()
        precondition(state.minute == 900 && !state.isPlaying)
        for day in state.days {
            precondition(day.hours.count == 9)
            precondition(day.hours.allSatisfy { $0.temperature >= day.low && $0.temperature <= day.high })
        }
        precondition(WeatherScene.allCases.count == 12)
        precondition(Set(WeatherScene.allCases.map(\.asset)).count == 12)
        precondition(WeatherScene.forecast(.sunny, minute: 720) == .sunny)
        precondition(WeatherScene.forecast(.sunny, minute: 1260) == .night)
        precondition(WeatherScene.forecast(.rainAndWind, minute: 1260) == .rainNight)
        for (minute, expected) in [(359, WeatherScene.night), (360, .dawn), (419, .dawn),
                                   (420, .sunny), (1019, .sunny), (1020, .sunset),
                                   (1079, .sunset), (1080, .night), (1439, .night)] {
            precondition(WeatherScene.forecast(.sunny, minute: minute) == expected)
        }
        precondition(WeatherScene.forecast(.rainy, minute: 360) == .rain)
        precondition(WeatherScene.forecast(.rainy, minute: 1080) == .rainNight)
        precondition(WeatherScene.allCases.filter(\.isDark).count == 3)
        precondition(WeatherScene.dawn.previewMinute == 360)
        precondition(WeatherScene.sunset.previewMinute == 1050)
        precondition(WeatherScene.night.previewMinute == 1260)
        precondition(WeatherScene.rainNight.previewMinute == 1320)
        precondition(WeatherScene.forecast(.cloudy, minute: 0) == .cloudy)
        for minute in 0...1439 {
            let start = SceneRuler.windowStart(minute: minute)
            precondition(start >= 0 && start + 480 <= 1439)
            precondition(minute >= start && minute <= start + 480)
        }
        precondition(SceneRuler.minute(start: 660, fraction: 0.5) == 900)
        precondition(SceneRuler.minute(start: 959, fraction: 2) == 1439)
        precondition(SceneRuler.minute(start: 0, fraction: -1) == 0)
        precondition(SceneRuler.minute(start: 660, fraction: .nan) == 660)
        print("PASS: selection, playback, scrubbing, bounds, reset, fixtures, 12 scenes, dawn/sunset/night boundaries, ruler windows and drag conversion")
    }
}
