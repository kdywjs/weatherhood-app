import SwiftUI

struct ContentView: View {
    @State private var showsProfile = false
    @State private var weather = MainWeatherState()

    var body: some View {
        NavigationStack {
            MainWeatherView(state: $weather, onProfile: { weather.pause(); showsProfile = true })
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showsProfile) { ProfileView() }
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
    static let background = Color(red: 245 / 255, green: 243 / 255, blue: 253 / 255)
    static let ink = Color(red: 31 / 255, green: 22 / 255, blue: 61 / 255)
    static let muted = Color(red: 116 / 255, green: 108 / 255, blue: 139 / 255)
}

/// Local visual prototype; account and weather services are not connected.
private struct ProfileView: View {
    @AppStorage("profile.nickname") private var nickname = "원종서"
    @AppStorage("profile.reduceMotion") private var reduceMotion = false
    @State private var editingName = false
    @State private var draftName = ""
    @State private var notice = ""
    @State private var showsNotice = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    profileHeader
                    VStack(alignment: .leading, spacing: 32) {
                        Button { inform("아바타 꾸미기는 준비 중이에요.") } label: {
                            Label("아바타 꾸미기", systemImage: "tshirt")
                                .font(.headline).frame(maxWidth: .infinity).frame(minHeight: 60)
                                .foregroundStyle(.white)
                                .background(ProfilePalette.violet, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        section("내 날씨") {
                            row("관심 지역 관리") { inform("관심 지역 관리는 준비 중이에요.") }
                            separator
                            row("기본 지역", value: "서울 중구") { inform("현재는 서울 중구의 샘플 예보를 사용해요. 지역 선택은 준비 중이에요.") }
                        }
                        section("내 설정") {
                            row("날씨 알림") { inform("알림 설정은 준비 중이에요. 현재 알림은 발송되지 않아요.") }
                            separator
                            HStack {
                                Text("캐릭터 움직임 줄이기")
                                Spacer()
                                Toggle("캐릭터 움직임 줄이기", isOn: $reduceMotion)
                                    .labelsHidden().tint(ProfilePalette.violet)
                            }
                            .frame(minHeight: 60)
                            .accessibilityHint("설정은 이 기기에 저장됩니다. 현재 캐릭터는 정지 이미지입니다")
                        }.id("settings")
                        section("도움말") {
                            row("사용 방법") { inform("메인에서 날짜와 시간을 선택하고 날씨 버튼으로 배경을 미리 볼 수 있어요. 우측 상단에서 마이페이지를 열어요.") }
                            separator
                            row("문의·의견 보내기") { inform("문의 채널은 준비 중이에요.") }
                        }
                        section("앱 정보") {
                            row("날씨 데이터 안내") { inform("현재 화면은 2026년 10월 10일 기준 가상 예보예요. 실제 날씨 데이터가 아닙니다.") }
                            separator
                            row("이용약관") { inform("이용약관은 준비 중이에요.") }
                            separator
                            row("개인정보 처리방침") { inform("개인정보 처리방침은 준비 중이에요.") }
                            separator
                            HStack {
                                Text("앱 버전")
                                Spacer()
                                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                                    .foregroundStyle(ProfilePalette.muted)
                            }.frame(minHeight: 60)
                        }
                        card {
                            NavigationLink { AccountPrototypeView() } label: { rowLabel("계정 관리") }
                                .buttonStyle(.plain)
                        }
                        Button("로그아웃") { inform("로그인 기능이 아직 연결되지 않은 미리보기입니다. 로그아웃은 실행되지 않아요.") }
                            .font(.subheadline.weight(.medium)).foregroundStyle(ProfilePalette.muted)
                            .frame(maxWidth: .infinity).frame(minHeight: 44)
                            .padding(.bottom, 20)
                            .id("profileBottom")
                    }.padding(.horizontal, 24)
                }
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
        .background(ProfilePalette.background)
        .foregroundStyle(ProfilePalette.ink)
        .font(.system(.body, weight: .medium))
        .preferredColorScheme(.light)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(ProfilePalette.violet, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .background(MinimalBackButton())
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

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProfilePalette.violet.frame(height: 116)
            VStack(alignment: .leading, spacing: 16) {
                Image("WeatherhoodVioletLight02")
                    .resizable().scaledToFill().frame(width: 148, height: 148)
                    .scaleEffect(1.45, anchor: .top)
                    .background(Color(red: 0.89, green: 0.86, blue: 0.98))
                    .clipShape(Circle()).overlay(Circle().stroke(.white, lineWidth: 5))
                    .accessibilityLabel("보라색 오리너구리 프로필")
                Text("\(nickname) 님").font(.largeTitle.bold())
                Button { draftName = nickname; editingName = true } label: {
                    Label("프로필 수정", systemImage: "pencil").font(.subheadline.weight(.semibold))
                        .foregroundStyle(ProfilePalette.muted).frame(minHeight: 44)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 24).padding(.top, -84)
        }
    }
    private var separator: some View { Divider().overlay(ProfilePalette.violet.opacity(0.15)) }
    private func inform(_ message: String) { notice = message; showsNotice = true }
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title3.bold()).padding(.leading, 8)
            card(content: content)
        }
    }
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0, content: content).padding(.horizontal, 20).padding(.vertical, 4)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
    private func rowLabel(_ title: String, value: String? = nil) -> some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer(minLength: 8)
            if let value { Text(value).foregroundStyle(ProfilePalette.muted) }
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(ProfilePalette.muted)
        }.frame(minHeight: 60).contentShape(Rectangle())
    }
    private func row(_ title: String, value: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) { rowLabel(title, value: value) }.buttonStyle(.plain)
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

/// Keep the native back gesture and button; only suppress its textual title.
private struct MinimalBackButton: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) { controller.configure() }
    final class Controller: UIViewController {
        override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); configure() }
        func configure() {
            guard let navigation = navigationController else { return }
            for controller in navigation.viewControllers { controller.navigationItem.backButtonDisplayMode = .minimal }
        }
    }
}

#Preview {
    ContentView()
}
