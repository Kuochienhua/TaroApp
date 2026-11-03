import SwiftUI

enum AppFonts {
    static func title(_ size: CGFloat = 36) -> Font {
        .custom("Georgia", size: size).bold()
    }
    static func cardName(_ size: CGFloat = 14) -> Font {
        .custom("Georgia", size: size)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, design: .serif)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, design: .serif)
    }
}
