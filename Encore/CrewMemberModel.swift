import Foundation

struct CrewMember: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var roles: [String]
    var email: String
}
