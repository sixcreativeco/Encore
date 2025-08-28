import SwiftUI
import FirebaseFirestore
import Kingfisher

struct ShowDaySheetPDF: View {
    let tour: Tour
    let show: Show
    let crew: [TourCrew]
    let config: ExportConfiguration
    let posterImage: NSImage?
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text(tour.artist.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            Text(tour.tourName.uppercased())
                .font(.system(size: 20, weight: .bold))

            // Main Info Card
            HStack(alignment: .top, spacing: 20) {
                // Left side: Text details
                VStack(alignment: .leading, spacing: 6) {
                    Text(dateFormatter.string(from: show.date.dateValue()))
                        .font(.system(size: 14, weight: .bold))
                    Text(show.city.uppercased())
                        .font(.system(size: 40, weight: .black))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(show.venueName)
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    if let loadInTime = show.loadIn {
                        Text("Load In Time: \(timeFormatter.string(from: loadInTime.dateValue()).lowercased())")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.vertical, 6).padding(.horizontal, 8)
                            .background(Color(white: 0.95))
                            .cornerRadius(6)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Label(show.venueAddress, systemImage: "mappin.and.ellipse")
                        if let phone = show.contactPhone, !phone.isEmpty {
                            Label(phone, systemImage: "phone.fill")
                        }
                        if let contact = show.contactName, !contact.isEmpty {
                            Label(contact, systemImage: "person.fill")
                        }
                    }
                    .font(.system(size: 11))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right side: Poster
                Group {
                    if let image = posterImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Color.gray.opacity(0.1)
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 130, height: 195)
                .clipped()
                .cornerRadius(8)
            }
            .frame(height: 195)
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            // Lower Section
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Timings").font(.system(size: 14, weight: .bold))
                    
                    if let time = show.loadIn {
                        timingRow(label: "Load In", time: time)
                    }
                    if let time = show.soundCheck {
                        timingRow(label: "Soundcheck", time: time)
                    }
                    if let time = show.doorsOpen {
                        timingRow(label: "Doors", time: time)
                    }
                    if let time = show.headlinerSetTime {
                        timingRow(label: "Set Time", time: time)
                    }
                    if let time = show.packOut {
                        timingRow(label: "Pack Out", time: time)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    if config.includeNotesSection {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(.system(size: 14, weight: .bold))
                            Text(config.notes.isEmpty ? "No notes provided." : config.notes)
                                .font(.system(size: 10))
                                .padding(10)
                                .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        }
                    }
                  
                    if config.includeCrew {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Crew").font(.system(size: 14, weight: .bold))
                            crewTable
                        }
                    }
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Spacer()
                Image("EncoreLogo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(height: 20)
                    .opacity(0.8)
                Spacer()
            }
        }
        .padding(40)
        .frame(width: 595, height: 842) // A4
        .background(Color(red: 247/255, green: 247/255, blue: 247/255))
        .foregroundColor(.black)
    }

    private func timingRow(label: String, time: Timestamp) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(timeFormatter.string(from: time.dateValue()).lowercased())
                .fontWeight(.semibold)
        }
        .font(.system(size: 10))
        .padding(8)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private var crewTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Name").bold().frame(maxWidth: .infinity, alignment: .leading)
                Text("Contact").bold().frame(width: 120, alignment: .leading)
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            ForEach(crew) { member in
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(member.name)
                        Text(member.roles.joined(separator: ", "))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // --- THIS IS THE CHANGE ---
                    VStack(alignment: .leading, spacing: 2) {
                        if let email = member.email, !email.isEmpty {
                            Text(email)
                        }
                        if let phone = member.phone, !phone.isEmpty {
                            Text(phone)
                        }
                    }
                    .frame(width: 120, alignment: .leading)
                    // --- END OF CHANGE ---
                }
                .font(.system(size: 10))
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
