import SwiftUI

@main
struct WeatherhoodApp: App {
    init() {
        WeatherhoodTypography.registerFonts()
        // Retired prototype setting; does not affect the iOS accessibility preference.
        UserDefaults.standard.removeObject(forKey: "profile.reduceMotion")
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(WeatherhoodTypography.font())
        }
    }
}
