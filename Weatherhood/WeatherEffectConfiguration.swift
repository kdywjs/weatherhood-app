import Foundation

/// Visual draft mapping. Does not classify visibility, hazards or snow accumulation.
struct WeatherEffectConfiguration: Equatable {
    var sky: SkyPreviewLevel = .unknown
    var precipitation = "none"
    var rain: RainPreviewLevel = .light
    var wind: WindPreviewLevel = .calm

    var rainFactor: CGFloat {
        switch precipitation {
        case "rain": 1
        case "rain_snow": 0.5
        default: 0
        }
    }
    var snowRate: CGFloat {
        switch precipitation {
        case "snow": 22
        case "rain_snow": 14
        default: 0
        }
    }
}

extension WeatherDeveloperValues {
    func effectConfiguration(sky: SkyPreviewLevel, rain: RainPreviewLevel, wind: WindPreviewLevel) -> WeatherEffectConfiguration {
        guard !slotMissing else { return WeatherEffectConfiguration() }
        var result = WeatherEffectConfiguration(sky: sky, precipitation: displayPrecipitation)
        if manualEffects {
            result.rain = rain
            result.wind = wind
        } else {
            func level(_ value: Double) -> RainPreviewLevel {
                if value < 3 { return .light }
                if value < 15 { return .moderate }
                if value < 30 { return .heavy }
                return .intense
            }
            // Never divide a daily total into an invented hourly rate.
            if abs(periodEnd.timeIntervalSince(periodStart) - 3600) < 1 {
                if amountKind == "exact" { result.rain = level(amount) }
                if amountKind == "range", upperUnbounded && lower >= 30 {
                    result.rain = .intense
                } else if amountKind == "range", !upperUnbounded, upper > lower {
                    let top = upperInclusive ? upper : upper.nextDown
                    if level(lower) == level(top) { result.rain = level(lower) }
                }
            }
            if !missing.contains("wind"), let speed = numbers["wind"] {
                result.wind = speed < 2 ? .calm : speed < 5 ? .light : speed < 9 ? .moderate : .strong
            }
        }
        return result
    }
}

enum RainPreviewLevel: String, CaseIterable, Identifiable {
    case none = "비 없음"
    case light = "약한 비 · 1mm/h"
    case moderate = "보통 비 · 7mm/h"
    case heavy = "강한 비 · 20mm/h"
    case intense = "매우 강한 비 · 35mm/h"
    var id: String { rawValue }
    var density: CGFloat {
        switch self {
        case .none: 0
        case .light: 0.35
        case .moderate: 1
        case .heavy: 2
        case .intense: 3
        }
    }
}

enum WindPreviewLevel: String, CaseIterable, Identifiable {
    case calm = "잔잔함 · 1m/s"
    case light = "약한 바람 · 3m/s"
    case moderate = "제법 부는 바람 · 7m/s"
    case strong = "강한 바람 · 12m/s"
    var id: String { rawValue }
    var angle: CGFloat {
        switch self {
        case .calm: 0
        case .light: 0.12
        case .moderate: 0.30
        case .strong: 0.52
        }
    }
}

