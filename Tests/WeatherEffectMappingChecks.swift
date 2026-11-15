import Foundation

@main
struct WeatherEffectMappingChecks {
    static func main() {
        var values = WeatherDeveloperValues()
        values.periodEnd = values.periodStart.addingTimeInterval(3600)
        func config() -> WeatherEffectConfiguration {
            values.effectConfiguration(sky: .overcast, rain: .intense, wind: .strong)
        }
        for (amount, expected) in [(0.0, RainPreviewLevel.light), (2.99, .light), (3, .moderate), (15, .heavy), (30, .intense)] {
            values.amount = amount
            precondition(config().rain == expected)
        }
        values.amountKind = "range"; values.lower = 3; values.upper = 15
        values.upperInclusive = false
        precondition(config().rain == .moderate)
        values.upperInclusive = true
        precondition(config().rain == .light)
        values.lower = 30; values.upperUnbounded = true
        precondition(config().rain == .intense)
        values.amountKind = "exact"; values.amount = 35
        values.periodEnd = values.periodStart.addingTimeInterval(86400)
        precondition(config().rain == .light)
        values.periodEnd = values.periodStart.addingTimeInterval(3600)
        values.amountKind = "null"
        precondition(config().rain == .light)
        for (raw, display) in [("rain", "rain"), ("shower", "rain"), ("drizzle", "rain"), ("snow", "snow"),
                               ("snow_flurries", "snow"), ("rain_snow", "rain_snow"), ("drizzle_snow_flurries", "rain_snow"),
                               ("none", "none"), ("null", "null"), ("unrecognized", "null")] {
            values.precipitation = raw
            precondition(config().precipitation == display)
            precondition(values.precipitation == raw)
        }
        for kind in ["none", "null", "snow"] {
            values.precipitation = kind
            precondition(config().rainFactor == 0)
        }
        values.precipitation = "snow"
        let snow = config().snowRate
        values.amountKind = "exact"; values.amount = 100
        precondition(config().snowRate == snow && snow > 0)
        values.precipitation = "rain_snow"
        precondition(config().rainFactor > 0 && config().snowRate > 0)
        for (speed, expected) in [(0.0, WindPreviewLevel.calm), (2, .light), (5, .moderate), (9, .strong)] {
            values.numbers["wind"] = speed
            precondition(config().wind == expected)
        }
        values.missing.insert("wind")
        precondition(config().wind == .calm)
        let baseline = config()
        values.numbers["humidity"] = 100
        values.numbers["temperature"] = -20
        values.numbers["probability"] = 100
        values.grades["hourlyPM10"] = "very_bad"
        values.grades["currentPM25"] = "very_bad"
        values.useCurrentAir = true
        values.hour = 23
        precondition(config() == baseline, "No fog, haze, temperature tint or fixed-hour night effect")
        values.manualEffects = true
        precondition(config().rain == .intense && config().wind == .strong)
        values.slotMissing = true
        precondition(config() == WeatherEffectConfiguration())
        precondition(values.display("humidity", unit: "%", hourly: true) == "정보 없음")
        print("PASS: precipitation grouping, boundaries, ranges, periods, missing data, manual override and excluded effects")
    }
}
