import SwiftUI

struct SearchView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Search")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.secondaryColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Search")
        }
    }
}

