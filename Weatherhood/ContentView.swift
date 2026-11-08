import SwiftUI

struct ContentView: View {
    @State private var showsProfile = false
    @State private var weather = MainWeatherState()
    @State private var profileWeather: (scene: WeatherScene, temperature: Int, preview: Bool)?

    var body: some View {
        NavigationStack {
            MainWeatherView(state: $weather, onProfile: { scene, temperature, preview in
                weather.pause()
                profileWeather = (scene, temperature, preview)
                showsProfile = true
            })
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showsProfile) {
                    ProfileView(
                        scene: profileWeather?.scene ?? WeatherScene.forecast(weather.selectedForecast.condition, minute: weather.minute),
                        temperature: profileWeather?.temperature ?? weather.selectedForecast.temperature,
                        weatherCaption: profileWeather?.preview == true ? "디자인 미리보기" : "\(weather.dateTimeLabel) · 샘플 예보"
                    )
                }
        }
        .tint(.accentColor)
        #if DEBUG
        .task {
            if ProcessInfo.processInfo.arguments.contains("--profile-preview") || ProcessInfo.processInfo.environment["WEATHERHOOD_PREVIEW_PROFILE"] == "1" {
                try? await Task.sleep(for: .milliseconds(300))
                showsProfile = true
            }
        }
        #endif
    }
}

private enum ProfilePalette {
    static let violet = Color(red: 149 / 255, green: 135 / 255, blue: 239 / 255)
    static let background = Color.white
    static let banner = Color(red: 241 / 255, green: 235 / 255, blue: 255 / 255)
    static let divider = Color(red: 237 / 255, green: 235 / 255, blue: 242 / 255)
    static let ink = Color(red: 31 / 255, green: 22 / 255, blue: 61 / 255)
    static let muted = Color(red: 116 / 255, green: 108 / 255, blue: 139 / 255)
}

/// Local visual prototype; account and weather services are not connected.
private struct ProfileView: View {
    let scene: WeatherScene
    let temperature: Int
    let weatherCaption: String
    @AppStorage("profile.nickname") private var nickname = "원종서"
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.openURL) private var openURL
    @State private var editingName = false
    @State private var draftName = ""
    @State private var notice = ""
    @State private var showsNotice = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 0) {
                        weatherCover.padding(.horizontal, -24)
                        profileHeader.padding(.top, 12)
                    }
                    avatarBanner
                    VStack(alignment: .leading, spacing: 32) {
                        section("내 날씨") {
                            row("관심 지역 관리", icon: "star") { inform("관심 지역 관리는 준비 중이에요.") }
                            row("기본 지역", icon: "mappin.and.ellipse", value: "서울 중구") { inform("현재는 서울 중구의 샘플 예보를 사용해요. 지역 선택은 준비 중이에요.") }
                        }
                        section("내 설정") {
                            row("알림 설정", icon: "bell") { inform("알림 설정은 준비 중이에요. 현재 알림은 발송되지 않아요.") }
                            row("위치 권한 설정", icon: "location") {
                                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                                    inform("iOS 설정에서 웨더후드 앱의 권한을 확인해 주세요.")
                                    return
                                }
                                openURL(url) { accepted in
                                    if !accepted { inform("설정을 열 수 없어요. iOS 설정에서 웨더후드를 선택해 주세요.") }
                                }
                            }
                        }.id("settings")
                        section("도움말") {
                            row("사용 방법", icon: "book") { inform("메인에서 날짜와 시간을 선택하고 날씨 버튼으로 배경을 미리 볼 수 있어요. 우측 상단에서 마이페이지를 열어요.") }
                            row("문의·의견 보내기", icon: "ellipsis.message") { inform("문의 채널은 준비 중이에요.") }
                        }
                        section("앱 정보") {
                            row("오픈소스 라이선스", icon: "chevron.left.forwardslash.chevron.right") { inform("오픈소스 라이선스 안내 화면은 준비 중이에요.") }
                            row("이용약관", icon: "doc.text") { inform("이용약관은 준비 중이에요.") }
                            row("개인정보 처리방침", icon: "lock.shield") { inform("개인정보 처리방침은 준비 중이에요.") }
                            rowLabel("앱 버전", icon: "info.circle", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        }
                        VStack(spacing: 0) {
                            NavigationLink { AccountPrototypeView() } label: { rowLabel("계정 관리", icon: "person.crop.circle", showsChevron: true) }
                                .buttonStyle(.plain)
                            row("로그아웃", icon: "rectangle.portrait.and.arrow.right", showsChevron: false) {
                                inform("로그인 기능이 아직 연결되지 않은 미리보기입니다. 로그아웃은 실행되지 않아요.")
                            }
                        }
                            .padding(.bottom, 20)
                            .id("profileBottom")
                    }.padding(.top, 8)
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
            #if DEBUG
            .task {
                if ProcessInfo.processInfo.arguments.contains("--profile-bottom") || ProcessInfo.processInfo.environment["WEATHERHOOD_PREVIEW_PROFILE_BOTTOM"] == "1" {
                    try? await Task.sleep(for: .milliseconds(1500))
                    proxy.scrollTo("profileBottom", anchor: .bottom)
                }
            }
            #endif
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(ProfilePalette.background)
        .foregroundStyle(ProfilePalette.ink)
        .font(WeatherhoodTypography.font(.body))
        .preferredColorScheme(.light)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(scene.isDark ? .dark : .light, for: .navigationBar)
        .tint(ProfilePalette.ink)
        .background(MinimalBackButton(disablesSwipeBack: true))
        .alert("안내", isPresented: $showsNotice) { Button("확인", role: .cancel) {} } message: { Text(notice) }
        .alert("프로필 수정", isPresented: $editingName) {
            TextField("닉네임", text: $draftName)
            Button("취소", role: .cancel) {}
            Button("저장") {
                let value = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { nickname = String(value.prefix(20)) }
            }
        } message: { Text("닉네임은 이 기기에 저장됩니다. 최대 20자까지 입력할 수 있어요.") }
    }

    private var weatherCover: some View {
        GeometryReader { geometry in
            Image(scene.asset)
                .resizable().scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                .clipped()
                .accessibilityLabel("서울 중구, \(scene.title), \(temperature)도. \(weatherCaption)")
        }
        .frame(height: 210)
        .accessibilityElement(children: .combine)
    }

    private var profileHeader: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(alignment: .center, spacing: 16))
        return layout {
                Image("WeatherhoodVioletLight02")
                    .resizable().scaledToFill().frame(width: 96, height: 96)
                    .scaleEffect(1.45, anchor: .top)
                    .background(ProfilePalette.banner)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                    .offset(y: typeSize.isAccessibilitySize ? 0 : -32)
                    .accessibilityLabel("보라색 오리너구리 프로필")
            VStack(alignment: .leading, spacing: 0) {
                Text("\(nickname) 님").font(WeatherhoodTypography.font(.title, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                Button { draftName = nickname; editingName = true } label: {
                    Text("프로필 수정").font(WeatherhoodTypography.font(.subheadline))
                        .foregroundStyle(ProfilePalette.muted).frame(minHeight: 44)
                }.buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    private var avatarBanner: some View {
        Button { inform("아바타 꾸미기는 준비 중이에요.") } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("아바타 꾸미기")
                        .font(WeatherhoodTypography.font(.title2, weight: .bold))
                        .foregroundStyle(Color(red: 52 / 255, green: 30 / 255, blue: 112 / 255))
                    Text("나만의 웨더후드를 꾸며보세요")
                        .font(WeatherhoodTypography.font(.footnote))
                        .foregroundStyle(ProfilePalette.muted)
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 20)
                if !typeSize.isAccessibilitySize {
                    Image("WeatherhoodVioletLight02")
                        .resizable().scaledToFill().frame(width: 100, height: 112)
                        .scaleEffect(1.4, anchor: .top).clipped().accessibilityHidden(true)
                }
            }
            .padding(.leading, 20).padding(.trailing, 8)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .background(ProfilePalette.banner, in: RoundedRectangle(cornerRadius: 16))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
    }
    private func inform(_ message: String) { notice = message; showsNotice = true }
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(WeatherhoodTypography.font(.title3, weight: .bold))
            VStack(spacing: 0, content: content)
            Rectangle().fill(ProfilePalette.divider).frame(height: 1).padding(.top, 8)
        }
    }
    private func rowLabel(_ title: String, icon: String, value: String? = nil, showsChevron: Bool = false) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 22, weight: .regular)).frame(width: 24)
                .accessibilityHidden(true)
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 8))
            layout {
                Text(title).fixedSize(horizontal: false, vertical: true)
                if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }
                if let value { Text(value).foregroundStyle(ProfilePalette.muted).fixedSize(horizontal: false, vertical: true) }
            }.frame(maxWidth: .infinity, alignment: .leading)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ProfilePalette.muted)
                    .accessibilityHidden(true)
            }
        }.frame(minHeight: 60).contentShape(Rectangle())
    }
    private func row(_ title: String, icon: String, value: String? = nil, showsChevron: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) { rowLabel(title, icon: icon, value: value, showsChevron: showsChevron) }.buttonStyle(.plain)
    }
}

private struct AccountPrototypeView: View {
    @State private var showsNotice = false
    var body: some View {
        List {
            Section {
                Text("계정 기능이 연결되지 않은 로컬 미리보기입니다.")
                    .foregroundStyle(.secondary)
            }
            Section {
                Button("회원 탈퇴", role: .destructive) { showsNotice = true }
            }
        }
        .navigationTitle("계정 관리").navigationBarTitleDisplayMode(.inline)
        .background(MinimalBackButton())
        .alert("회원 탈퇴 준비 중", isPresented: $showsNotice) {
            Button("확인", role: .cancel) {}
        } message: { Text("계정 서비스 연결 전이므로 실제 탈퇴나 데이터 삭제는 실행되지 않아요.") }
    }
}

/// Preserve the native back button, optionally disabling swipe-back for this screen only.
private struct MinimalBackButton: UIViewControllerRepresentable {
    var disablesSwipeBack = false
    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller()
        controller.disablesSwipeBack = disablesSwipeBack
        return controller
    }
    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.disablesSwipeBack = disablesSwipeBack
        controller.configure()
    }
    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) {
        controller.restoreGestures()
    }
    final class Controller: UIViewController {
        var disablesSwipeBack = false
        private var isActive = false
        private var savedGestures: [(UIGestureRecognizer, Bool)] = []
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            isActive = true
            configure()
        }
        override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); configure() }
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            isActive = false
            restoreGestures()
        }
        func restoreGestures() {
            for (gesture, wasEnabled) in savedGestures { gesture.isEnabled = wasEnabled }
            savedGestures.removeAll()
        }
        func configure() {
            guard let navigation = navigationController else { return }
            for controller in navigation.viewControllers { controller.navigationItem.backButtonDisplayMode = .minimal }
            guard isActive else { return }
            guard disablesSwipeBack else { restoreGestures(); return }
            var gestures = [navigation.interactivePopGestureRecognizer].compactMap { $0 }
            if #available(iOS 26.0, *), let gesture = navigation.interactiveContentPopGestureRecognizer {
                gestures.append(gesture)
            }
            for gesture in gestures {
                if !savedGestures.contains(where: { $0.0 === gesture }) {
                    savedGestures.append((gesture, gesture.isEnabled))
                }
                gesture.isEnabled = false
            }
        }
    }
}

#Preview {
    let _ = WeatherhoodTypography.registerFonts()
    ContentView()
        .font(WeatherhoodTypography.font())
}
