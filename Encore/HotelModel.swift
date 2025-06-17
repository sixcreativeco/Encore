import Foundation

struct HotelModel: Identifiable, Hashable {
    var id: String { "\(name.lowercased())-\(address.lowercased())" }
    var name: String
    var address: String
    var city: String
    var bookingReference: String?
    var contactName: String?
    var contactEmail: String?
    var contactPhone: String?

    init(name: String, address: String, city: String, bookingReference: String? = nil, contactName: String? = nil, contactEmail: String? = nil, contactPhone: String? = nil) {
        self.name = name
        self.address = address
        self.city = city
        self.bookingReference = bookingReference
        self.contactName = contactName
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
    }
}

extension HotelModel {
    func matches(_ query: String) -> Bool {
        let lowered = query.lowercased()
        return name.lowercased().contains(lowered)
            || address.lowercased().contains(lowered)
            || city.lowercased().contains(lowered)
            || (bookingReference ?? "").lowercased().contains(lowered)
            || (contactName ?? "").lowercased().contains(lowered)
            || (contactEmail ?? "").lowercased().contains(lowered)
            || (contactPhone ?? "").lowercased().contains(lowered)
    }
}
