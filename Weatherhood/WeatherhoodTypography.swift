import SwiftUI
import CoreText
import UIKit

/// The only type family for app-authored text. SF Symbols and OS-owned UI are exceptions.
enum WeatherhoodTypography {
    enum Weight { case regular, bold }
    static let regularName = "LINESeedSansKR-Regular"
    static let boldName = "LINESeedSansKR-Bold"

    static func font(_ style: Font.TextStyle = .body, weight: Weight = .regular) -> Font {
        let size: CGFloat
        switch style {
        case .largeTitle: size = 34
        case .title: size = 28
        case .title2: size = 22
        case .title3: size = 20
        case .headline, .body: size = 17
        case .callout: size = 16
        case .subheadline: size = 15
        case .footnote: size = 13
        case .caption: size = 12
        case .caption2: size = 11
        @unknown default: size = 17
        }
        return font(size: size, relativeTo: style, weight: weight)
    }

    static func font(size: CGFloat, relativeTo style: Font.TextStyle = .body,
                     weight: Weight = .regular) -> Font {
        .custom(weight == .bold ? boldName : regularName, size: size, relativeTo: style)
    }

    /// Only for sizes already scaled with @ScaledMetric. Avoids applying Dynamic Type twice.
    static func scaledFont(size: CGFloat, weight: Weight = .regular) -> Font {
        .custom(weight == .bold ? boldName : regularName, fixedSize: size)
    }

    @MainActor static func registerFonts() {
        for (file, name) in [("LINESeedKR-Rg", regularName), ("LINESeedKR-Bd", boldName)] {
            guard UIFont(name: name, size: 17) == nil else { continue }
            guard let url = Bundle.main.url(forResource: file, withExtension: "ttf", subdirectory: "Fonts") else {
                preconditionFailure("Missing bundled font: \(file)")
            }
            var error: Unmanaged<CFError>?
            let registered = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            precondition(registered && UIFont(name: name, size: 17) != nil,
                         "LINE Seed KR registration failed: \(String(describing: error))")
        }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline)
            .scaledFont(for: UIFont(name: boldName, size: 17)!)]
        appearance.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle)
            .scaledFont(for: UIFont(name: boldName, size: 34)!)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
