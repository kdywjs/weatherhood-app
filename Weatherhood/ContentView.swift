import SwiftUI

struct ContentView: View {
    @State private var showsProfile = false
    @State private var weather = MainWeatherState()

    var body: some View {
        MainWeatherView(state: $weather, onProfile: { weather.pause(); showsProfile = true })
            .tint(.accentColor)
            .sheet(isPresented: $showsProfile) {
                NavigationStack {
                    ContentUnavailableView("마이 준비 중", systemImage: "person",
                                           description: Text("마이 화면은 추후 연결할 예정이에요."))
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("닫기") { showsProfile = false }
                            }
                        }
                }
            }
    }
}

#Preview {
    ContentView()
}
