import SwiftUI

struct ContentRouter: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.isLoggedIn {
            SidebarContainerView()
        } else {
            SignInView()
        }
    }
}
