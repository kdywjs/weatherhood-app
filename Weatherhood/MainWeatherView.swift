import SwiftUI
import Combine

/// Approved urban illustration plates; all interface controls remain native SwiftUI.
struct MainWeatherView: View {
    @Binding var state: MainWeatherState
    var onProfile: () -> Void = {}
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var notice: MainNotice?
    @State private var previewScene: WeatherScene?
    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize = 88
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var scene: WeatherScene {
        previewScene ?? WeatherScene.forecast(state.selectedForecast.condition, minute: state.minute)
    }
    private var ink: Color { scene.isDark || scene == .rain ? .white : WeatherTheme.ink }
    private var temperature: Int { previewScene?.sampleTemperature ?? state.selectedForecast.temperature }

    var body: some View {
        GeometryReader { geometry in
            let height = max(700, geometry.size.height)
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    header
                    selectors.padding(.top, 8)
                    if typeSize.isAccessibilitySize {
                        sceneContent(height: temperatureSize * 1.5 + 120)
                        Image(scene.asset).resizable().scaledToFit()
                            .accessibilityLabel("도시의 \(scene.title) 풍경과 보라색 오리너구리")
                            .padding(.vertical, 16)
                    } else {
                        sceneContent(height: height - 252)
                    }
                    timeline
                    footer
                }
                .frame(minHeight: height, alignment: .top)
                .padding(.horizontal, 24)
                .background {
                    if !typeSize.isAccessibilitySize {
                        Image(scene.asset).resizable().scaledToFill()
                            .frame(width: geometry.size.width,
                                   height: height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom + 40)
                            .clipped().accessibilityHidden(true)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .background((scene.isDark || scene == .rain ? Color(red: 0.10, green: 0.16, blue: 0.25) : Color(red: 0.84, green: 0.91, blue: 0.98)).ignoresSafeArea())
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
        .onAppear {
            if let value = ProcessInfo.processInfo.environment["WEATHERHOOD_PREVIEW_SCENE"],
               let selection = WeatherScene(rawValue: value) { selectPreview(selection) }
        }
        #endif
    }

    private var header: some View {
        Text("WEATHERHOOD")
            .font(.system(.caption2, design: .rounded, weight: .heavy)).tracking(3)
            .frame(maxWidth: .infinity).frame(height: 44)
            .overlay(alignment: .trailing) {
                Button { state.pause(); onProfile() } label: {
                    Image(systemName: "person.crop.circle").font(.title3).frame(width: 44, height: 44)
                }
                .buttonStyle(.plain).accessibilityLabel("마이 화면")
            }
    }
    private var selectors: some View {
        Group {
            if typeSize.isAccessibilitySize {
            VStack(spacing: 8) { locationButton; dateMenu }
            } else {
                HStack(spacing: 10) { locationButton; dateMenu }
            }
        }
    }
    private var locationButton: some View {
        Button { state.pause(); notice = .location } label: { pill("서울 중구", icon: "mappin.and.ellipse") }
            .buttonStyle(.plain)
    }
    private var dateMenu: some View {
        Menu {
            ForEach(state.days) { day in
                Button { state.selectDay(day.id); previewScene = nil } label: {
                    if state.selectedDayIndex == day.id {
                        Label("\(day.shortLabel) · \(day.dateLabel)", systemImage: "checkmark")
                    } else { Text("\(day.shortLabel) · \(day.dateLabel)") }
                }
            }
        } label: { pill("\(state.selectedDay.shortLabel) · \(state.selectedDay.dateLabel)", icon: "calendar") }
    }
    private func pill(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title).lineLimit(1)
            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
        }
        .font(.caption.weight(.semibold)).foregroundStyle(WeatherTheme.ink)
        .padding(.horizontal, 13).frame(minHeight: 44).frame(maxWidth: .infinity)
        .background(.white.opacity(0.86), in: Capsule())
    }
    private func sceneContent(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(temperature)°")
                .font(.system(size: temperatureSize, weight: .heavy, design: .rounded)).monospacedDigit()
                .foregroundStyle(scene.temperatureColor)
                .shadow(color: .white.opacity(0.85), radius: 1, x: 0, y: -2)
                .shadow(color: scene.temperatureColor.opacity(0.25), radius: 2, x: 1, y: 4)
                .lineLimit(1).minimumScaleFactor(0.6)
                .accessibilityLabel("\(temperature)도").padding(.top, 24)
            Menu {
                Button("선택 시간의 샘플 예보로 돌아가기") { previewScene = nil }
                Section("디자인 미리보기 · 실제 날씨 아님") {
                    ForEach(WeatherScene.allCases) { item in
                        Button { selectPreview(item) } label: {
                            Label(item.title, systemImage: item.symbol)
                        }
                    }
                }
            } label: {
                Label {
                    HStack(spacing: 7) {
                        Text(scene.title)
                        Image(systemName: "chevron.right").font(.caption2.bold())
                    }
                } icon: { Image(systemName: scene.symbol) }
                .font(.caption.weight(.semibold)).foregroundStyle(WeatherTheme.ink)
                .padding(.horizontal, 14).frame(minHeight: 44)
                .background(.white.opacity(0.86), in: Capsule())
            }
            .accessibilityLabel("\(scene.title), 날씨별 디자인 미리보기")
            Spacer(minLength: 0)
            Color.clear.frame(height: 1)
                .accessibilityElement()
                .accessibilityLabel("손을 흔드는 보라색 오리너구리 웨더후드")
        }
        .frame(maxWidth: .infinity, alignment: .leading).frame(height: height)
    }
    private var timeline: some View {
        VStack(spacing: 0) {
            Text(previewScene == nil ? "\(state.timeLabel) · 샘플 예보" : "\(scene.title) · 디자인 미리보기")
                .font(.caption2.bold()).foregroundStyle(ink)
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
                .font(.caption.bold()).padding(.horizontal, 16).frame(minHeight: 44)
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
                            .font(.system(size: 9, weight: .semibold)).monospacedDigit().frame(maxWidth: .infinity)
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
