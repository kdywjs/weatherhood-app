import SwiftUI
import Combine

/// Approved urban illustration plates; all interface controls remain native SwiftUI.
struct MainWeatherView: View {
    @Binding var state: MainWeatherState
    var onProfile: (WeatherScene, Int, Bool) -> Void = { _, _, _ in }
    var showsSelectedDate = false
    @State private var showsWeekly = false
    @GestureState(resetTransaction: Transaction(animation: .easeInOut(duration: 0.2)))
    private var switcherDrag: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var notice: MainNotice?
    @State private var previewScene: WeatherScene?
    @State private var effectPreview = false
    @State private var previewRain: RainPreviewLevel = .moderate
    @State private var previewWind: WindPreviewLevel = .light
    @State private var previewSky: SkyPreviewLevel = .overcast
    @State private var developerValues = WeatherDeveloperValues()
    @State private var showsDeveloperSettings = false
    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize = 88
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var scene: WeatherScene {
        previewScene ?? WeatherScene.forecast(state.selectedForecast.condition, minute: state.minute)
    }
    private var ink: Color { scene.isDark || scene == .rain ? .white : WeatherTheme.ink }
    private var temperature: Int { previewScene?.sampleTemperature ?? state.selectedForecast.temperature }
    private var displayedCondition: String {
        guard effectPreview else { return scene.title }
        if developerValues.slotMissing { return "시간 정보 없음" }
        return developerValues.precipitation == "none" ? previewSky.rawValue : developerValues.precipitationTitle
    }
    private var hasRainEffect: Bool {
        effectPreview || scene == .rain || scene == .rainNight || scene == .storm
    }
    private var developerEffects: WeatherEffectConfiguration {
        developerValues.effectConfiguration(sky: previewSky, rain: previewRain, wind: previewWind)
    }
    private var backgroundAsset: String {
        if effectPreview { return developerValues.slotMissing ? WeatherScene.cloudy.asset : previewSky.asset }
        return hasRainEffect ? WeatherScene.cloudy.asset : scene.asset
    }
    private var backgroundShade: Double {
        if effectPreview { return developerValues.slotMissing ? 0 : previewSky.shade }
        guard hasRainEffect && !effectPreview else { return 0 }
        return 0.08
    }
    // The thumb and forecast share a normalized position, regardless of screen width.
    private var weeklyProgress: CGFloat {
        min(1, max(0, (showsWeekly ? 1 : 0) + switcherDrag))
    }

    var body: some View {
        GeometryReader { geometry in
            let height = max(560, geometry.size.height)
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    header
                    selectors.padding(.top, 8)
                    if typeSize.isAccessibilitySize {
                        sceneContent(height: temperatureSize * 1.5 + 120)
                            .opacity(1 - weeklyProgress)
                        Image(backgroundAsset).resizable().scaledToFit()
                            .overlay(Color.black.opacity(backgroundShade))
                            .accessibilityLabel("도시의 \(scene.title) 풍경과 보라색 오리너구리")
                            .padding(.vertical, 16)
                            .opacity(1 - weeklyProgress)
                    } else {
                        sceneContent(height: height - 252)
                            .opacity(1 - weeklyProgress)
                    }
                    timeline
                        .opacity(1 - weeklyProgress)
                    footer
                        .opacity(1 - weeklyProgress)
                }
                .frame(minHeight: height, alignment: .top)
                .padding(.horizontal, 24)
                .contentShape(Rectangle())
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(showsWeekly)
            .allowsHitTesting(!showsWeekly)
            .accessibilityHidden(showsWeekly)
            .overlay(alignment: .top) {
                WeatherInfoView(state: $state, componentOnly: true)
                            .scrollDisabled(false)
                            .padding(.horizontal, 24)
                            .padding(.top, typeSize.isAccessibilitySize ? 160 : 108)
                            .contentShape(Rectangle())
                            .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { value in
                                guard value.translation.width > 60,
                                      abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                                closeWeekly()
                            })
                            .accessibilityAction(named: "주간 날씨 닫기", closeWeekly)
                            .offset(x: geometry.size.width * (1 - weeklyProgress))
                            .allowsHitTesting(showsWeekly && switcherDrag == 0)
                            .accessibilityHidden(!showsWeekly)
            }
            .clipped()
        }
        .safeAreaInset(edge: .bottom, spacing: 8) {
            VStack(spacing: 0) {
                #if DEBUG
                developerMenu
                #endif
            weatherSwitcher
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
        .background {
            GeometryReader { backgroundGeometry in
                // Rain is animated separately; never use a plate with baked-in streaks.
                Image(backgroundAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: backgroundGeometry.size.width, height: backgroundGeometry.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(backgroundShade))
                    .overlay {
                        if !reduceMotion && hasRainEffect {
                            RainBackground(active: scenePhase == .active,
                                           rain: effectPreview ? previewRain : .moderate,
                                           wind: effectPreview ? previewWind : .light,
                                           effects: effectPreview ? developerEffects : nil)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
        }
        .foregroundStyle(ink)
        .preferredColorScheme(scene.isDark || scene == .rain ? .dark : .light)
        .alert(item: $notice) { item in
            Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("확인")))
        }
        .onReceive(clock) { _ in if scenePhase == .active { state.advance() } }
        .onChange(of: scenePhase) { _, phase in if phase != .active { state.pause() } }
        .onDisappear { state.pause() }
        #if DEBUG
        .sheet(isPresented: $showsDeveloperSettings) {
            WeatherDeveloperSettings(values: $developerValues, sky: $previewSky,
                                     enabled: $effectPreview, rain: $previewRain, wind: $previewWind)
        }
        .onChange(of: effectPreview) { _, enabled in
            if enabled { state.pause() }
        }
        .onAppear {
            if ProcessInfo.processInfo.environment["WEATHERHOOD_DEVELOPER_SETTINGS"] == "1" {
                showsDeveloperSettings = true
            }
            if let value = ProcessInfo.processInfo.environment["WEATHERHOOD_PREVIEW_SCENE"],
               let selection = WeatherScene(rawValue: value) { selectPreview(selection) }
        }
        #endif
    }

    #if DEBUG
    private var developerMenu: some View {
        Menu {
            Button("스펙 전체 설정") { state.pause(); showsDeveloperSettings = true }
            Toggle("배경 효과 미리보기", isOn: $effectPreview)
            Picker("강수 형태", selection: $developerValues.precipitation) {
                ForEach(WeatherDeveloperValues.precipitationOptions, id: \.0) { Text($0.1).tag($0.0) }
            }
            Picker("하늘 상태 · 가안", selection: $previewSky) {
                ForEach(SkyPreviewLevel.allCases) { sky in
                    Text(sky.rawValue).tag(sky)
                }
            }
            Picker("강수 단계 · 수동 비교", selection: Binding(get: { previewRain }, set: { previewRain = $0; developerValues.manualEffects = true })) {
                ForEach(RainPreviewLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            Picker("바람 단계 · 수동 비교", selection: Binding(get: { previewWind }, set: { previewWind = $0; developerValues.manualEffects = true })) {
                ForEach(WindPreviewLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            Text("단계 선택 후 미리보기를 켜세요. 수치는 테스트값입니다.")
            Toggle("수동 강도 비교", isOn: $developerValues.manualEffects)
            Text("배경: 하늘·강수·풍속. 기온별 의상·대기질 등급별 마스크는 미연동입니다. 안개·연무·시각별 낮밤 효과는 없습니다.")
            if reduceMotion { Text("동작 줄이기가 켜져 있어 효과가 숨겨집니다.") }
            Button("미리보기 종료", role: .cancel) { effectPreview = false }
        } label: {
            VStack(spacing: 2) {
                Label(effectPreview ? "개발자 모드 · 테스트 중" : "개발자 모드", systemImage: "slider.horizontal.3")
                if effectPreview {
                    Text("\(previewSky.rawValue) · \(developerValues.slotMissing ? "시간 정보 없음" : developerValues.precipitationTitle) · 가안")
                    Text(developerValues.manualEffects ? "수동: \(previewRain.rawValue) / \(previewWind.rawValue)" : "설정 데이터로 배경 연출 중")
                }
            }
            .font(WeatherhoodTypography.font(.caption2, weight: .bold))
            .foregroundStyle(WeatherTheme.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .environment(\.colorScheme, .light)
        }
        .padding(.bottom, 4)
    }
    #endif

    private var weatherSwitcher: some View {
        GeometryReader { geometry in
            let segment = (geometry.size.width - 6) / 2
            let position = segment * weeklyProgress
            ZStack(alignment: .leading) {
                Capsule().fill(.ultraThinMaterial).padding(.vertical, 4)
                Capsule()
                    .fill(.white.opacity(0.88))
                    .frame(width: segment, height: 30)
                    .offset(x: 3 + position)
                HStack(spacing: 0) {
                    switchLabel("현재 날씨", selected: position < segment / 2)
                    switchLabel("주간 날씨", selected: position >= segment / 2)
                }
                .padding(.horizontal, 3)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .updating($switcherDrag) { value, translation, transaction in
                    transaction.animation = nil
                    translation = value.translation.width / max(1, segment)
                }
                .onChanged { _ in state.pause() }
                .onEnded { value in
                    let isTap = abs(value.translation.width) < 4 && abs(value.translation.height) < 4
                    let target = isTap
                        ? value.location.x > geometry.size.width / 2
                        : (showsWeekly ? segment : 0) + value.predictedEndTranslation.width > segment / 2
                    if target != showsWeekly {
                        if target { openWeekly() } else { closeWeekly() }
                    }
                })
        }
        .frame(height: 44)
        .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 216)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("날씨 화면 전환")
        .accessibilityValue(showsWeekly ? "주간 날씨" : "현재 날씨")
        .accessibilityAdjustableAction { direction in
            if direction == .increment { openWeekly() }
            else if direction == .decrement { closeWeekly() }
        }
    }

    private func switchLabel(_ title: String, selected: Bool) -> some View {
            Text(title)
                .font(WeatherhoodTypography.font(.footnote, weight: .bold))
                .foregroundStyle(selected ? Color(red: 0.36, green: 0.18, blue: 0.85) : .white)
                .frame(maxWidth: .infinity, minHeight: 44)
    }

    private var header: some View {
        Text("WEATHERHOOD")
            .font(WeatherhoodTypography.font(.caption2, weight: .bold)).tracking(3)
            .frame(maxWidth: .infinity).frame(height: 44)
            .overlay(alignment: .trailing) {
                Button { state.pause(); onProfile(scene, temperature, previewScene != nil) } label: {
                    Image(systemName: "person.crop.circle").font(.title3).frame(width: 44, height: 44)
                }
                .buttonStyle(.plain).accessibilityLabel("마이 화면")
            }
    }
    private var selectors: some View {
        VStack(spacing: 8) {
            locationButton
            if showsSelectedDate {
                Text("\(state.selectedDay.dateLabel) (\(state.selectedDay.weekday))")
                    .font(WeatherhoodTypography.font(.callout, weight: .bold))
                    .accessibilityLabel("선택 날짜 \(state.selectedDay.dateLabel), \(state.selectedDay.weekday)요일")
            }
        }
        .frame(maxWidth: .infinity)
    }
    private var locationButton: some View {
        Button { state.pause(); notice = .location } label: {
            Text("서울 중구")
                .font(WeatherhoodTypography.font(.caption, weight: .bold))
                .foregroundStyle(ink)
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("서울 중구, 지역 선택")
    }
    private func sceneContent(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
                Text(effectPreview ? (developerValues.slotMissing || developerValues.missing.contains("temperature") ? "—°" : "\(developerValues.numbers["temperature", default: 12].formatted())°") : "\(temperature)°")
                .font(WeatherhoodTypography.scaledFont(size: temperatureSize, weight: .bold)).monospacedDigit()
                .foregroundStyle(scene.temperatureColor)
                .shadow(color: .white.opacity(0.85), radius: 1, x: 0, y: -2)
                .shadow(color: scene.temperatureColor.opacity(0.25), radius: 2, x: 1, y: 4)
                .lineLimit(1).minimumScaleFactor(0.6)
                .contentShape(Rectangle())
            .accessibilityLabel(effectPreview ? "테스트 기온" : "\(temperature)도")
            .padding(.top, 24)
                Label(displayedCondition, systemImage: effectPreview ? "testtube.2" : scene.symbol)
                .font(WeatherhoodTypography.font(.caption, weight: .bold)).foregroundStyle(WeatherTheme.ink)
                .padding(.horizontal, 14).frame(minHeight: 44)
                .background(.white.opacity(0.86), in: Capsule())
            .accessibilityLabel(displayedCondition)
            if effectPreview {
                Text(developerValues.informationSummary)
                    .font(WeatherhoodTypography.font(.caption2))
                    .foregroundStyle(WeatherTheme.ink)
                    .padding(10)
                    .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 8)
            }
            Spacer(minLength: 0)
            Color.clear.frame(height: 1)
                .accessibilityElement()
                .accessibilityLabel("손을 흔드는 보라색 오리너구리 웨더후드")
        }
        .frame(maxWidth: .infinity, alignment: .leading).frame(height: height)
        .contentShape(Rectangle())
        .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { value in
            guard !showsWeekly,
                  value.translation.width < -60,
                  abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
            openWeekly()
        })
        .accessibilityAction(named: "주간 날씨 보기", openWeekly)
    }
    private var timeline: some View {
        VStack(spacing: 0) {
            Text(effectPreview ? String(format: "%02d:00 · 개발자 테스트", developerValues.hour) : (previewScene == nil ? "\(state.timeLabel) · 샘플 예보" : "\(scene.title) · 디자인 미리보기"))
                .font(WeatherhoodTypography.font(.caption2, weight: .bold)).foregroundStyle(ink)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(scene.isDark || scene == .rain ? Color.black.opacity(0.5) : Color.white.opacity(0.8), in: Capsule())
            HStack(spacing: 4) {
                Button { scrub(state.minute - 60) } label: {
                    Image(systemName: "chevron.left").frame(width: 32, height: 44)
                }
                .disabled(state.minute == 0).accessibilityLabel("한 시간 이전")
                SceneTimeRuler(minute: state.minute, ink: ink) { scrub($0) }
                    .background(scene.isDark || scene == .rain ? Color.black.opacity(0.3) : Color.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                Button { scrub(state.minute + 60) } label: {
                    Image(systemName: "chevron.right").frame(width: 32, height: 44)
                }
                .disabled(state.minute == MainWeatherState.lastMinute).accessibilityLabel("한 시간 이후")
            }
            .buttonStyle(.plain)
        }
    }
    private func openWeekly() {
        state.pause()
        withAnimation(.easeInOut(duration: 0.2)) { showsWeekly = true }
    }

    private func closeWeekly() {
        withAnimation(.easeInOut(duration: 0.2)) { showsWeekly = false }
    }

    private func scrub(_ minute: Int) {
        previewScene = nil
        state.scrub(to: Double(minute))
    }
    private func selectPreview(_ selection: WeatherScene) {
        state.scrub(to: Double(selection.previewMinute))
        previewScene = selection
    }
    private var footer: some View {
        HStack(spacing: 10) {
            Button { previewScene = nil; state.togglePlayback() } label: {
                Image(systemName: state.isPlaying ? "pause.fill" : "play.fill").frame(width: 44, height: 44)
            }
            .accessibilityLabel(state.isPlaying ? "재생 정지" : "샘플 날씨 재생")
            .background(.white.opacity(0.86), in: Circle())
            Button { state.pause(); notice = .avatar } label: {
                HStack(spacing: 8) {
                    Image(systemName: "tshirt")
                    Text("아바타 꾸미기")
                    Image(systemName: "chevron.right").font(.caption2.bold())
                }
                .font(WeatherhoodTypography.font(.caption, weight: .bold)).padding(.horizontal, 16).frame(minHeight: 44)
                .background(.white.opacity(0.86), in: Capsule())
            }
            Button { previewScene = nil; state.resetToCurrent() } label: {
                Image(systemName: "arrow.counterclockwise").frame(width: 44, height: 44)
            }
            .accessibilityLabel("샘플 현재 시각으로 초기화").background(.white.opacity(0.86), in: Circle())
        }
        .foregroundStyle(WeatherTheme.ink).buttonStyle(.plain).padding(.top, 8).padding(.bottom, 12)
    }
}

private enum MainNotice: String, Identifiable {
    case location, avatar
    var id: String { rawValue }
    var title: String { self == .location ? "지역 선택 준비 중" : "아바타 꾸미기 준비 중" }
    var message: String {
        self == .location
            ? "서울 중구의 가상 예보예요. 2026년 10월 10일 15시 기준이며 실제 날씨가 아닙니다. 지역 검색은 추후 연결할 예정이에요."
            : "선택한 Violet-Light-02 캐릭터를 적용했어요. 의상 변경과 꾸미기는 추후 연결할 예정이에요."
    }
}

/// Interactive time ruler; the drag origin stays fixed throughout a gesture.
private struct SceneTimeRuler: View {
    let minute: Int
    let ink: Color
    let onChange: (Int) -> Void
    @State private var dragStart: Int?
    private var start: Int { dragStart ?? SceneRuler.windowStart(minute: minute) }
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            VStack(spacing: 3) {
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        ForEach(0..<49) { tick in
                            Rectangle().fill(ink.opacity(tick % 6 == 0 ? 0.65 : 0.3))
                                .frame(width: 1, height: tick % 6 == 0 ? 17 : 8).frame(maxWidth: .infinity)
                        }
                    }
                    Capsule().fill(Color.accentColor).frame(width: 3, height: 26)
                        .offset(x: max(0, min(width - 3, CGFloat(minute - start) / 480 * width)))
                }
                .frame(height: 28)
                HStack {
                    ForEach(0..<5) { index in
                        Text(String(format: "%02d:%02d", (start + index * 120) / 60, (start + index * 120) % 60))
                            .font(WeatherhoodTypography.font(size: 9, relativeTo: .caption2, weight: .bold)).monospacedDigit().frame(maxWidth: .infinity)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                if dragStart == nil { dragStart = start }
                onChange(SceneRuler.minute(start: start, fraction: Double(value.location.x / max(1, width))))
            }.onEnded { _ in dragStart = nil })
        }
        .frame(height: 48)
        .accessibilityElement(children: .ignore).accessibilityLabel("날씨 시각")
        .accessibilityValue(String(format: "%02d시 %02d분", minute / 60, minute % 60))
        .accessibilityAdjustableAction { direction in
            if direction == .increment { onChange(minute + 60) }
            else if direction == .decrement { onChange(minute - 60) }
        }
    }
}

extension WeatherScene {
    var temperatureColor: Color {
        switch self {
        case .sunny, .hot: Color(red: 0.83, green: 0.39, blue: 0.04)
        case .cloudy, .wind: Color(red: 0.22, green: 0.34, blue: 0.46)
        case .snow, .cold: Color(red: 0.08, green: 0.36, blue: 0.72)
        case .rain: Color(red: 0.85, green: 0.94, blue: 1)
        case .night, .rainNight, .storm, .dawn, .sunset: Color(red: 0.95, green: 0.97, blue: 1)
        }
    }
}
