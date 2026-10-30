import SwiftUI

enum WeatherTheme {
    static let ink = Color("WeatherInk")
    static let muted = Color("WeatherMuted")
    static let scene = Color("WeatherScene")
    static let selection = Color("WeatherSelection")
    static let track = Color("WeatherTrack")
    static let horizontalInset: CGFloat = 20
}

struct DesignIcon: View {
    let name: String
    var body: some View {
        Image(name)
            .renderingMode(.original)
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
    }
}

/// Figma 19:211의 장식 레이어를 원래 좌표와 크기로 보존합니다.
/// 새 캐릭터를 적용할 때 이 컴포넌트만 교체할 수 있습니다.
struct WeatherCharacter: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            layer("CharacterShadow", x: 87.78, y: 209.22, width: 109, height: 16)
            layer("CharacterGround", x: 17.16, y: 209.88, width: 250, height: 1)
            layer("CharacterBody", x: 97.68, y: 47.52, width: 90, height: 172)
            layer("UmbrellaStem", x: 178.2, y: 50.82, width: 9, height: 95)
            layer("UmbrellaCanopy", x: 136.62, y: 22.44, width: 97, height: 32)
            layer("CharacterWeather", x: 23.1, y: 51.48, width: 239, height: 135)
        }
        .frame(width: 283.8, height: 242.22, alignment: .topLeading)
        .accessibilityLabel("우산을 든 임시 캐릭터")
    }

    private func layer(_ asset: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        Image(asset)
            .resizable()
            .frame(width: width, height: height)
            .offset(x: x, y: y)
    }
}
