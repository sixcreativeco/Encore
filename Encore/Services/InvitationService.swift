import Foundation
import FirebaseFirestore

class InvitationService {
    static let shared = InvitationService()
    private let db = Firestore.firestore()

    enum InvitationError: Error {
        case notFound
        case expired
        case crewDocumentMissing
        case tourDocumentMissing
        case userAlreadyExists
        case unknown
    }

    struct InvitationDetails {
        let code: String // The invitation code itself
        let invitation: Invitation
        let tour: Tour
        let crew: TourCrew
    }

    func fetchInvitationDetails(with code: String, completion: @escaping (Result<InvitationDetails, Error>) -> Void) {
        let invitationRef = db.collection("invitations").document(code)

        invitationRef.getDocument { document, error in
            guard let document = document, document.exists,
                  let invitation = try? document.data(as: Invitation.self) else {
                completion(.failure(InvitationError.notFound))
                return
            }

            if invitation.expiresAt.dateValue() < Date() {
                completion(.failure(InvitationError.expired))
                invitationRef.delete()
                return
            }

            let crewRef = self.db.collection("tourCrew").document(invitation.crewDocId)
            let tourRef = self.db.collection("tours").document(invitation.tourId)
            
            var fetchedCrew: TourCrew?
            var fetchedTour: Tour?
            let group = DispatchGroup()

            group.enter()
            crewRef.getDocument { doc, _ in
                fetchedCrew = try? doc?.data(as: TourCrew.self)
                group.leave()
            }

            group.enter()
            tourRef.getDocument { doc, _ in
                fetchedTour = try? doc?.data(as: Tour.self)
                group.leave()
            }

            group.notify(queue: .main) {
                guard let crew = fetchedCrew else {
                    completion(.failure(InvitationError.crewDocumentMissing))
                    return
                }
                guard let tour = fetchedTour else {
                    completion(.failure(InvitationError.tourDocumentMissing))
                    return
                }

                // Pass the original code along with the fetched details
                let details = InvitationDetails(code: code, invitation: invitation, tour: tour, crew: crew)
                completion(.success(details))
            }
        }
    }
    
    func acceptInvitation(withCode code: String, forNewUser userId: String, completion: @escaping (Error?) -> Void) {
        let invitationRef = db.collection("invitations").document(code)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let invitationSnapshot: DocumentSnapshot
            do {
                try invitationSnapshot = transaction.getDocument(invitationRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let crewDocId = invitationSnapshot.data()?["crewDocId"] as? String else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Crew document ID missing from invitation."])
                errorPointer?.pointee = error
                return nil
            }
            
            let crewRef = self.db.collection("tourCrew").document(crewDocId)
            
            transaction.updateData([
                "userId": userId,
                "status": InviteStatus.accepted.rawValue
            ], forDocument: crewRef)
            
            transaction.deleteDocument(invitationRef)
            
            return nil
        }) { (object, error) in
            completion(error)
        }
    }
}
