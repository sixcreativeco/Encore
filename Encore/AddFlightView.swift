import SwiftUI

struct AddFlightView: View {
    var tourID: String
    var onFlightAdded: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var flightNumber = ""
    @State private var flightDate = Date()
    @State private var isLoading = false
    @State private var fetchedFlight: FlightModel? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Add Flight")
                    .font(.title.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Flight Number")
                            .font(.subheadline)
                        TextField("e.g. NZ101", text: $flightNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Flight Date")
                            .font(.subheadline)
                        DatePicker("", selection: $flightDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
            }

            if isLoading { ProgressView() }

            if let fetched = fetchedFlight {
                flightPreview(fetched)
                Button("Confirm & Add") {
                    saveFlight(fetched)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: { fetchFlightData() }) {
                    Text("Search Flight")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(flightNumber.isEmpty)
            }

            if let error = errorMessage {
                Text(error).foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .frame(width: 500, height: 500)
    }

    private func flightPreview(_ flight: FlightModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(flight.airline) \(flight.flightNumber)").font(.headline)
            Text("\(flight.departureAirport) → \(flight.arrivalAirport)").font(.subheadline)
            Text("Departs: \(formattedDate(flight.departureTime))").font(.caption)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private func fetchFlightData() {
        isLoading = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = formatter.string(from: flightDate)

        AviationStackAPI.fetchFlightByFlightNumberAndDate(
            flightIATA: flightNumber,
            flightDate: formattedDate
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let flight):
                    self.fetchedFlight = flight
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func saveFlight(_ flight: FlightModel) {
        FirebaseFlightService.saveFlight(tourID: tourID, flight: flight) {
            self.onFlightAdded()
            self.dismiss()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
