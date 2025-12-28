import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .recordings
    
    enum Tab: Hashable {
        case recordings
        case search
        case settings
    }
}

