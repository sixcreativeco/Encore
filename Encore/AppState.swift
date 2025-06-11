import Foundation

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userID: String? = nil
}
