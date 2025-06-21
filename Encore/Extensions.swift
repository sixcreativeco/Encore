import Foundation
import FirebaseFirestore

// This extension teaches Swift how to compare two Timestamps.
extension Timestamp: Comparable {
    public static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        return lhs.dateValue() < rhs.dateValue()
    }
}
