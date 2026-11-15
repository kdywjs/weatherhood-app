import SwiftUI

// Local inspection values, not an API response or production weather thresholds.
struct WeatherDeveloperValues {
    var manualEffects = false
    var useCurrentAir = false
    var precipitation = "rain"
    var slotMissing = false
    var hour = 15
    var amountKind = "exact"
    var amount = 7.0
    var lower = 0.0
    var upper = 1.0
    var upperUnbounded = false
    var lowerInclusive = true
    var upperInclusive = false
    var periodStart = Date()
    var periodEnd = Date().addingTimeInterval(3600)
    var numbers: [String: Double] = ["current": 12, "temperature": 12, "min": 10, "max": 18,
                                    "wind": 3, "humidity": 70, "probability": 60,
                                    "currentPM10": 25, "currentPM25": 12, "hourlyPM10": 25, "hourlyPM25": 12]
    var missing: Set<String> = []
    var grades = ["currentPM10": "good", "currentPM25": "good", "hourlyPM10": "good", "hourlyPM25": "good"]
    var airStart = Date().addingTimeInterval(-3600)
    var airEnd = Date()
    var hourlyAirStart = Date().addingTimeInterval(-3600)
    var hourlyAirEnd = Date()

    static let precipitationTypes = [("none", "없음"), ("rain", "비"), ("shower", "소나기"),
        ("snow", "눈"), ("rain_snow", "비·눈"), ("drizzle", "빗방울"),
        ("drizzle_snow_flurries", "빗방울·눈날림"), ("snow_flurries", "눈날림"), ("null", "정보 없음")]
    static let precipitationOptions = [("none", "없음"), ("rain", "비"), ("snow", "눈"), ("rain_snow", "비·눈 혼합"), ("null", "정보 없음")]
    var displayPrecipitation: String {
        switch precipitation {
        case "shower", "drizzle": "rain"
        case "snow_flurries": "snow"
        case "drizzle_snow_flurries": "rain_snow"
        case "none", "rain", "snow", "rain_snow": precipitation
        default: "null"
        }
    }
    var precipitationTitle: String { Self.precipitationOptions.first { $0.0 == displayPrecipitation }?.1 ?? "정보 없음" }
    func display(_ key: String, unit: String, hourly: Bool = false) -> String {
        guard !(hourly && slotMissing), !missing.contains(key), let value = numbers[key] else { return "정보 없음" }
        return "\(value.formatted())\(unit)"
    }

    var informationSummary: String {
        let prefix = useCurrentAir ? "current" : "hourly"
        let labels = ["good": "좋음", "moderate": "보통", "bad": "나쁨", "very_bad": "매우 나쁨"]
        let air = ["PM10", "PM25"].map { suffix in
            let key = prefix + suffix
            let grade = !useCurrentAir && slotMissing ? "정보 없음" : labels[grades[key, default: "null"], default: "정보 없음"]
            return "\(suffix == "PM25" ? "PM2.5" : suffix) \(display(key, unit: "µg/m³", hourly: !useCurrentAir)) · \(grade)"
        }.joined(separator: " / ")
        return "최신 \(display("current", unit: "°")) · 최저 \(display("min", unit: "°")) / 최고 \(display("max", unit: "°"))\n풍속 \(display("wind", unit: "m/s", hourly: true)) · 습도 \(display("humidity", unit: "%", hourly: true)) · 강수확률 \(display("probability", unit: "%", hourly: true))\n\(useCurrentAir ? "최신" : "시간별") \(air)"
    }
}

enum SkyPreviewLevel: String, CaseIterable, Identifiable {
    case sunny = "맑음"
    case partlyCloudy = "구름 많음"
    case overcast = "흐림"
    case unknown = "정보 없음"
    var id: String { rawValue }
    var asset: String { self == .sunny ? WeatherScene.sunny.asset : WeatherScene.cloudy.asset }
    var shade: Double { self == .overcast ? 0.16 : 0 }
}

#if DEBUG
struct WeatherDeveloperSettings: View {
    @Binding var values: WeatherDeveloperValues
    @Binding var sky: SkyPreviewLevel
    @Binding var enabled: Bool
    @Binding var rain: RainPreviewLevel
    @Binding var wind: WindPreviewLevel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("미리보기 적용", isOn: $enabled)
                    Text("표현 기준은 하늘·강수 형태·강수량·풍속·기온·대기질 등급과 일출·일몰 7가지입니다. 배경은 앞의 4가지를 사용합니다. 기온별 의상과 등급별 마스크는 기준·자산 확정 후 연결합니다. 일출·일몰과 실제 API는 아직 연결하지 않았습니다.")
                }
                Section("선택 시간 · Asia/Seoul") {
                    Picker("시간", selection: $values.hour) {
                        ForEach(0..<24) { Text(String(format: "%02d:00", $0)).tag($0) }
                    }
                    Toggle("시간 슬롯 전체 정보 없음", isOn: $values.slotMissing)
                    Text("한 시간의 테스트값을 편집합니다. 앱의 24시간 예보를 덮어쓰지 않습니다.")
                }
                Section("하늘·강수 형태") {
                    Picker("하늘", selection: $sky) {
                        ForEach(SkyPreviewLevel.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("강수 형태", selection: $values.precipitation) {
                        ForEach(WeatherDeveloperValues.precipitationOptions, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    Text("하늘 상태에 따라 움직이는 구름의 양과 햇빛을 변경합니다. 정보 없음은 중립 배경으로 표시합니다.")
                }
                Section("최신 기온 · 하루 공통") {
                    number("현재 기온", key: "current", unit: "°C", range: -50...50)
                    number("오늘 최저", key: "min", unit: "°C", range: -50...50)
                    number("오늘 최고", key: "max", unit: "°C", range: -50...50)
                    if !values.missing.contains("min") && !values.missing.contains("max") && values.numbers["min", default: 0] > values.numbers["max", default: 0] {
                        Text("최저가 최고보다 큽니다. 테스트값을 확인하세요.").foregroundStyle(.orange)
                    }
                }
                Section("시간별 값") {
                    number("기온", key: "temperature", unit: "°C", range: -50...50)
                    number("풍속", key: "wind", unit: "m/s", range: 0...60)
                    number("습도", key: "humidity", unit: "%", range: 0...100)
                    number("강수확률", key: "probability", unit: "%", range: 0...100)
                }.disabled(values.slotMissing)
                Section("강수량 · mm") {
                    Picker("값 형식", selection: $values.amountKind) {
                        Text("정확한 수치").tag("exact")
                        Text("범위").tag("range")
                        Text("정보 없음").tag("null")
                    }
                    if values.amountKind == "exact" {
                        Stepper("강수량: \(values.amount.formatted()) mm", value: $values.amount, in: 0...300, step: 0.5)
                    } else if values.amountKind == "range" {
                        Stepper("하한: \(values.lower.formatted()) mm", value: $values.lower, in: 0...299, step: 0.5)
                        Toggle("하한 포함", isOn: $values.lowerInclusive)
                        Toggle("상한 없음", isOn: $values.upperUnbounded)
                        if !values.upperUnbounded {
                            Stepper("상한: \(values.upper.formatted()) mm", value: $values.upper, in: 0.5...300, step: 0.5)
                            Toggle("상한 포함", isOn: $values.upperInclusive)
                            if values.upper <= values.lower { Text("상한은 하한보다 커야 합니다.").foregroundStyle(.orange) }
                        }
                    }
                    if values.amountKind != "null" {
                        DatePicker("집계 시작", selection: $values.periodStart)
                        DatePicker("집계 종료", selection: $values.periodEnd)
                        if values.periodStart >= values.periodEnd { Text("종료는 시작보다 뒤여야 합니다.").foregroundStyle(.orange) }
                    }
                    Text("0과 정보 없음은 별개입니다. 범위·집계 기간은 그대로 보존하며 시간당 값으로 임의 환산하지 않습니다.")
                }.disabled(values.slotMissing)
                airSection("최신 미세먼지 요약", prefix: "current")
                airSection("시간별 미세먼지", prefix: "hourly").disabled(values.slotMissing)
                Section("배경 연출 · 가안") {
                    Toggle("수동 강도 비교", isOn: $values.manualEffects)
                    Toggle("대기질 정보에 최신 요약 사용", isOn: $values.useCurrentAir)
                    Picker("비 연출 강도", selection: $rain) {
                        ForEach(RainPreviewLevel.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("바람 연출 강도", selection: $wind) {
                        ForEach(WindPreviewLevel.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Text("기본은 입력한 강수량·풍속을 사용합니다. 수동 비교를 켜면 단계로 덮어씁니다. 강수량은 1시간 집계만 강도로 변환하며 범위가 여러 단계를 걸치면 약한 기본 효과를 사용합니다. 눈의 양은 강수량 mm로 추정하지 않습니다. 습도·대기질·기온·시각으로 안개·연무·배경 색감·낮밤을 만들지 않습니다.")
                }
                Section {
                    Button("테스트값 초기화") {
                        values = WeatherDeveloperValues()
                        sky = .overcast
                        rain = .moderate
                        wind = .light
                    }
                    Button("미리보기 종료") { enabled = false; dismiss() }
                }
            }
            .font(WeatherhoodTypography.font(.callout))
            .navigationTitle("날씨 개발자 설정")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
            .environment(\.timeZone, TimeZone(identifier: "Asia/Seoul")!)
        }
    }

    private func number(_ title: String, key: String, unit: String, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading) {
            Toggle("\(title) 정보 없음", isOn: Binding(
                get: { values.missing.contains(key) },
                set: { if $0 { values.missing.insert(key) } else { values.missing.remove(key) } }))
            if !values.missing.contains(key) {
                Stepper("\(title): \(values.numbers[key, default: 0].formatted()) \(unit)", value: Binding(
                    get: { values.numbers[key, default: 0] }, set: { values.numbers[key] = $0 }), in: range)
            }
        }
    }

    private func airSection(_ title: String, prefix: String) -> some View {
        Section(title) {
            ForEach(["PM10", "PM25"], id: \.self) { suffix in
                let key = prefix + suffix
                number(suffix == "PM10" ? "미세먼지 PM10" : "초미세먼지 PM2.5", key: key, unit: "µg/m³", range: 0...1000)
                Picker("\(suffix) 1시간 등급", selection: Binding(get: { values.grades[key, default: "null"] }, set: { values.grades[key] = $0 })) {
                    Text("좋음").tag("good")
                    Text("보통").tag("moderate")
                    Text("나쁨").tag("bad")
                    Text("매우 나쁨").tag("very_bad")
                    Text("정보 없음").tag("null")
                }
            }
            if prefix == "current" {
                DatePicker("집계 시작", selection: $values.airStart)
                DatePicker("집계 종료", selection: $values.airEnd)
                if values.airStart >= values.airEnd { Text("집계 종료는 시작보다 뒤여야 합니다.").foregroundStyle(.orange) }
            } else {
                DatePicker("집계 시작", selection: $values.hourlyAirStart)
                DatePicker("집계 종료", selection: $values.hourlyAirEnd)
                if values.hourlyAirStart >= values.hourlyAirEnd { Text("집계 종료는 시작보다 뒤여야 합니다.").foregroundStyle(.orange) }
            }
            Text("농도와 등급의 누락을 따로 선택합니다. 둘 다 없으면 해당 항목은 null입니다. 최신 요약과 시간별 값은 서로 복사하지 않습니다.")
        }
    }
}
#endif
