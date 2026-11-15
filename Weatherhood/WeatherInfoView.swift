import SwiftUI

/// Main-tab continuation that presents the weekly forecast without the character scene.
struct WeatherInfoView: View {
    @Binding var state: MainWeatherState
    var componentOnly = false

    @Environment(\.dynamicTypeSize) private var typeSize

    private var selectedScene: WeatherScene {
        WeatherScene.forecast(state.selectedForecast.condition, minute: state.minute)
    }

    private var backgroundAsset: String {
        switch selectedScene {
        case .rain, .rainNight, .storm: "SceneRain"
        case .snow, .cold: "SceneSnow"
        case .cloudy, .wind: "SceneCloudy"
        case .sunny, .hot, .dawn, .sunset, .night: "SceneSunny"
        }
    }

    var body: some View {
        if componentOnly {
            ScrollView(.vertical) {
                weeklyForecast
                    .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
        } else {
        GeometryReader { geometry in
            ZStack {
                Image(backgroundAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .accessibilityHidden(true)

                Color.black.opacity(0.10)
                    .ignoresSafeArea()

                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                        locationPill
                        currentSummary
                        insight
                        weeklyForecast
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
        }
    }

    private var header: some View {
        Text("WEATHERHOOD")
            .font(WeatherhoodTypography.font(.caption2, weight: .bold))
            .tracking(3)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private var locationPill: some View {
        HStack(spacing: 7) {
            Image(systemName: "mappin.and.ellipse")
            Text("서울 중구")
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
        }
        .font(WeatherhoodTypography.font(.caption, weight: .bold))
        .foregroundStyle(WeatherTheme.ink)
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(.white.opacity(0.88), in: Capsule())
        .accessibilityLabel("선택 지역 서울 중구")
    }

    private var currentSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(state.selectedForecast.temperature)°")
                .font(WeatherhoodTypography.scaledFont(size: typeSize.isAccessibilitySize ? 76 : 88, weight: .bold))
                .monospacedDigit()
                .shadow(color: .black.opacity(0.20), radius: 2, x: 0, y: 2)

            HStack(spacing: 10) {
                Label(state.selectedForecast.condition.title, systemImage: state.selectedForecast.condition.symbol)
                    .font(WeatherhoodTypography.font(.caption, weight: .bold))
                    .foregroundStyle(WeatherTheme.ink)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(.white.opacity(0.88), in: Capsule())

                Text("최저 \(state.selectedDay.low)° / 최고 \(state.selectedDay.high)°")
                    .font(WeatherhoodTypography.font(.callout, weight: .bold))
                    .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
            }
        }
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("현재 \(state.selectedForecast.temperature)도, \(state.selectedForecast.condition.title), 최저 \(state.selectedDay.low)도, 최고 \(state.selectedDay.high)도")
    }

    private var insight: some View {
        HStack(spacing: 10) {
            Image(systemName: "cloud.rain")
                .foregroundStyle(.blue)
            Text(rainInsight)
                .font(WeatherhoodTypography.font(.callout, weight: .bold))
                .foregroundStyle(WeatherTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 58)
        .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private var rainInsight: String {
        state.selectedDay.condition == .rainy || state.selectedDay.condition == .rainAndWind
            ? "오후 4시부터 비가 시작돼요"
            : "오늘은 큰 비 소식이 없어요"
    }

    private var weeklyForecast: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("주간 날씨", systemImage: "calendar")
                .font(WeatherhoodTypography.font(.title2, weight: .bold))
                .foregroundStyle(WeatherTheme.ink)
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(state.days) { day in
                    forecastRow(day)
                        .accessibilityElement(children: .combine)

                    if day.id != state.days.last?.id {
                        Divider()
                            .overlay(WeatherInfoPalette.violet.opacity(0.20))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(.white.opacity(0.90), in: RoundedRectangle(cornerRadius: 24))
    }

    private func forecastRow(_ day: DayForecast) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.shortLabel)
                    .font(WeatherhoodTypography.font(.body, weight: .bold))
                Text(day.dateLabel + " (" + day.weekday + ")")
                    .font(WeatherhoodTypography.font(.caption2))
                    .foregroundStyle(WeatherTheme.ink.opacity(0.72))
            }
            .frame(width: 76, alignment: .leading)

            VStack(spacing: 4) {
                Image(systemName: day.condition.symbol)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(day.condition == .sunny ? .yellow : .blue)
                    .accessibilityHidden(true)
                Text(day.condition.title)
                    .font(WeatherhoodTypography.font(.caption2))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 44)

            Text("\(day.low)° / \(day.high)°")
                .font(WeatherhoodTypography.font(.callout, weight: .bold))
                .monospacedDigit()
                .frame(width: 82, alignment: .leading)

            TemperatureRangeBar(low: day.low, high: day.high, allDays: state.days)
                .frame(maxWidth: .infinity)

        }
        .foregroundStyle(WeatherTheme.ink)
        .padding(.horizontal, 8)
        .frame(minHeight: 78)
        .background(day.id == state.selectedDayIndex ? WeatherInfoPalette.violet.opacity(0.16) : .clear,
                    in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
    }
}

private struct TemperatureRangeBar: View {
    let low: Int
    let high: Int
    let allDays: [DayForecast]

    var body: some View {
        GeometryReader { geometry in
            let minimum = allDays.map(\.low).min() ?? low
            let maximum = allDays.map(\.high).max() ?? high
            let span = max(1, maximum - minimum)
            let start = CGFloat(low - minimum) / CGFloat(span) * geometry.size.width
            let width = CGFloat(high - low) / CGFloat(span) * geometry.size.width

            ZStack(alignment: .leading) {
                Capsule().fill(WeatherInfoPalette.violet.opacity(0.20))
                Capsule()
                    .fill(LinearGradient(colors: [.blue, WeatherInfoPalette.violet], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(12, width))
                    .offset(x: start)
            }
        }
        .frame(height: 8)
        .accessibilityLabel("최저 \(low)도에서 최고 \(high)도까지")
    }
}

private enum WeatherInfoPalette {
    static let violet = Color(red: 149 / 255, green: 135 / 255, blue: 239 / 255)
}

private extension WeatherCondition {
    var symbol: String {
        switch self {
        case .cloudy: "cloud"
        case .sunny: "sun.max"
        case .rainy, .rainAndWind: "cloud.rain"
        }
    }
}
