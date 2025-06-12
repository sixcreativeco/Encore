import SwiftUI
import MapKit

struct ShowDetailView: View {
    let show: ShowModel
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion()
    @State private var mapItem: MKMapItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                // Header: Date + City + Venue + Load In + Map
                HStack(alignment: .top, spacing: 40) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(show.date.formatted(date: .numeric, time: .omitted))
                            .font(.system(size: 16))
                            .foregroundColor(.gray)

                        Text(show.city.uppercased())
                            .font(.system(size: 42, weight: .bold))

                        Text(show.venue)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.gray)

                        if let loadIn = show.loadIn {
                            Label {
                                Text("Load In Time: \(loadIn.formatted(date: .omitted, time: .shortened))")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.black)
                            } icon: {
                                Image(systemName: "truck")
                                    .font(.system(size: 13))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }

                    Spacer()

                    Map(coordinateRegion: $mapRegion, annotationItems: annotationItems()) { item in
                        MapMarker(coordinate: item.coordinate, tint: .red)
                    }
                    .cornerRadius(12)
                    .frame(width: 500, height: 180)
                }

                // Contact Info + Buttons (2x1 layout)
                HStack(alignment: .top, spacing: 40) {
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 18))
                            Text(show.address)
                                .font(.system(size: 16))
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "phone")
                                .font(.system(size: 18))
                            Text("09 358 1250")
                                .font(.system(size: 16))
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 18))
                            Text("Venue Contact")
                                .font(.system(size: 16))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 16) {
                        StyledActionButton(title: "Edit Show", icon: "pencil", color: .blue)
                        StyledActionButton(title: "Upload Documents", icon: "tray.and.arrow.up", color: .green)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()

                // 3 panels
                HStack(alignment: .top, spacing: 16) {
                    panel(title: "Show Timings")
                    panel(title: "Guest List")
                    panel(title: "Guest List")
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .onAppear { loadMapForAddress() }
        }
        .navigationTitle("Show Details")
    }

    private func panel(title: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            Spacer()
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.10))
        .cornerRadius(10)
    }

    private func annotationItems() -> [MapItemWrapper] {
        guard let item = mapItem else { return [] }
        return [MapItemWrapper(coordinate: item.placemark.coordinate)]
    }

    private func loadMapForAddress() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = show.address

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first else { return }
            self.mapItem = mapItem
            self.mapRegion = MKCoordinateRegion(
                center: mapItem.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }

    struct MapItemWrapper: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
}

// MARK: - StyledActionButton

struct StyledActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Button(action: { }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(width: 220, height: 44)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
