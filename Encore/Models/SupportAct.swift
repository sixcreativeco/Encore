import Foundation
import FirebaseFirestore

struct SupportAct: Codable, Identifiable {
    @DocumentID var id: String?
    let tourId: String
    var name: String
    var type: ActType
    var contactEmail: String?

    enum ActType: String, Codable {
        case Touring, Local
    }
}
