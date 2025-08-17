import Foundation

// This struct provides a static, offline list of common timezones for the dropdown menu.
struct TimezoneHelper {

    struct TimezoneRegion: Identifiable {
        let id = UUID()
        let name: String
        let timezones: [Timezone]
    }

    struct Timezone: Identifiable, Hashable {
        let id = UUID()
        let name: String // e.g., "Auckland"
        let identifier: String // e.g., "Pacific/Auckland"
    }

    static let regions: [TimezoneRegion] = [
        TimezoneRegion(name: "Pacific", timezones: [
            Timezone(name: "Auckland", identifier: "Pacific/Auckland"),
            Timezone(name: "Sydney", identifier: "Australia/Sydney"),
            Timezone(name: "Melbourne", identifier: "Australia/Melbourne"),
            Timezone(name: "Brisbane", identifier: "Australia/Brisbane"),
            Timezone(name: "Perth", identifier: "Australia/Perth"),
            Timezone(name: "Honolulu", identifier: "Pacific/Honolulu"),
        ]),
        TimezoneRegion(name: "North America", timezones: [
            Timezone(name: "Los Angeles (PT)", identifier: "America/Los_Angeles"),
            Timezone(name: "Denver (MT)", identifier: "America/Denver"),
            Timezone(name: "Chicago (CT)", identifier: "America/Chicago"),
            Timezone(name: "New York (ET)", identifier: "America/New_York"),
            Timezone(name: "Vancouver", identifier: "America/Vancouver"),
            Timezone(name: "Toronto", identifier: "America/Toronto"),
        ]),
        TimezoneRegion(name: "Europe", timezones: [
            Timezone(name: "London", identifier: "Europe/London"),
            Timezone(name: "Paris", identifier: "Europe/Paris"),
            Timezone(name: "Berlin", identifier: "Europe/Berlin"),
            Timezone(name: "Amsterdam", identifier: "Europe/Amsterdam"),
            Timezone(name: "Dublin", identifier: "Europe/Dublin"),
        ]),
        TimezoneRegion(name: "Asia", timezones: [
            Timezone(name: "Tokyo", identifier: "Asia/Tokyo"),
            Timezone(name: "Singapore", identifier: "Asia/Singapore"),
            Timezone(name: "Hong Kong", identifier: "Asia/Hong_Kong"),
            Timezone(name: "Dubai", identifier: "Asia/Dubai"),
        ]),
    ]
}
