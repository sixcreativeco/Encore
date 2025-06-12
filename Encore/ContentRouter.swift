import SwiftUI

struct ContentRouter: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.userID == nil {
            SignInView(appState: _appState)
        } else {
            TourListView()
                .environmentObject(appState)
        }
    }
}
