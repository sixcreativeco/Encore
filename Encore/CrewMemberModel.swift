import Foundation

struct CrewMember: Identifiable {
    var id = UUID().uuidString
    var name: String
    var email: String
    var roles: [String]
}
