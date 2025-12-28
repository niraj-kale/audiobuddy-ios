import SwiftUI

enum Theme {
    static let primaryColor = Color.accentColor
    static let secondaryColor = Color.secondary
    static let backgroundColor = Color(uiColor: .systemBackground)
    
    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let body = Font.body
        static let caption = Font.caption
    }
}

