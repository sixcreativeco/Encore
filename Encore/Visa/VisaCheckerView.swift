import Foundation
import SwiftUI

// A model to manage the state of a single passport check.
struct PassportCheck: Identifiable {
    let id = UUID()
    let country: Country
    var isLoading: Bool = true
    var visaInfo: VisaInfo?
    var errorMessage: String?
}

// A view model to encapsulate the logic for the VisaCheckerView.
@MainActor
class VisaCheckViewModel: ObservableObject {
    @Published var passportChecks: [PassportCheck] = []
    @Published var passportInputText: String = ""
    
    let destinationAirport: AirportEntry
    
    init(destinationAirport: AirportEntry) {
        self.destinationAirport = destinationAirport
    }
    
    /// Adds a new passport to the list and fetches its visa requirements.
    func addAndCheckPassport(country: Country) {
        // Prevent adding duplicates.
        guard !passportChecks.contains(where: { $0.country.code == country.code }) else {
            passportInputText = ""
            return
        }
        
        let newCheck = PassportCheck(country: country)
        passportChecks.append(newCheck)
        passportInputText = ""
        
        Task {
            do {
                let destinationCountryString = destinationAirport.country
                var foundCode = CountryDataSource.findCode(forName: destinationCountryString)

                if foundCode == nil && destinationCountryString.count == 2 {
                    if CountryDataSource.countries.contains(where: { $0.code.uppercased() == destinationCountryString.uppercased() }) {
                        foundCode = destinationCountryString.uppercased()
                    }
                }
                
                guard let destinationCode = foundCode else {
                    throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Could not find country code for destination."])
                }

                let info = try await VisaService.shared.fetchVisaRequirements(
                    passportCode: country.code,
                    destinationCode: destinationCode
                )
                
                if let index = passportChecks.firstIndex(where: { $0.id == newCheck.id }) {
                    passportChecks[index].visaInfo = info
                    passportChecks[index].isLoading = false
                }
            } catch {
                if let index = passportChecks.firstIndex(where: { $0.id == newCheck.id }) {
                    passportChecks[index].errorMessage = error.localizedDescription
                    passportChecks[index].isLoading = false
                }
            }
        }
    }
    
    func removeCheck(at offsets: IndexSet) {
        passportChecks.remove(atOffsets: offsets)
    }
}

// The main UI for the visa checker feature.
struct VisaCheckerView: View {
    @StateObject private var viewModel: VisaCheckViewModel
    
    init(destinationAirport: AirportEntry) {
        _viewModel = StateObject(wrappedValue: VisaCheckViewModel(destinationAirport: destinationAirport))
    }

    private var suggestedCountries: [Country] {
        if viewModel.passportInputText.isEmpty { return [] }
        return CountryDataSource.countries.filter {
            $0.name.lowercased().contains(viewModel.passportInputText.lowercased()) &&
            !viewModel.passportChecks.contains(where: { $0.country.code == $0.country.code })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Header
            Text("Visa Requirements for \(viewModel.destinationAirport.city), \(viewModel.destinationAirport.country)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Passport Input
            VStack(alignment: .leading) {
                // --- THIS IS THE FIX: The Add Button is now removed ---
                StyledInputField(placeholder: "Add Passport Country (e.g., USA)...", text: $viewModel.passportInputText)
                
                if !suggestedCountries.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(suggestedCountries.prefix(5)) { country in
                                Button(action: { viewModel.addAndCheckPassport(country: country) }) {
                                    Text(country.name)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                }
            }
            
            // Results List
            if viewModel.passportChecks.isEmpty {
                Text("Add one or more passport countries to check their visa requirements for this destination.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(12)
            } else {
                ForEach(viewModel.passportChecks) { check in
                    VisaResultCardView(check: check)
                }
            }
        }
    }
}

// A card view to display the result of a single visa check.
fileprivate struct VisaResultCardView: View {
    let check: PassportCheck
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(check.visaInfo?.statusColor ?? .gray)
                .frame(width: 8)
            
            if check.isLoading {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let info = check.visaInfo {
                content(for: info)
            } else if let error = check.errorMessage {
                errorContent(error)
            }
        }
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(minHeight: 80)
    }
    
    private func content(for info: VisaInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                // Top section: Passport and Status
                VStack(alignment: .leading) {
                    Text(info.passportOf)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(info.visa)
                        .font(.title3.bold())
                        .foregroundColor(info.statusColor)
                }
                
                // Middle section: Details
                HStack(spacing: 24) {
                    detailItem(title: "Max Stay", value: info.stayOf)
                    detailItem(title: "Passport Validity", value: info.passValid)
                }
                
                // Bottom section: Links
                HStack(spacing: 20) {
                    if let urlString = info.link, let url = URL(string: urlString), !urlString.isEmpty {
                        Link(destination: url) {
                            Label("Apply for eVisa/eTA", systemImage: "link")
                        }
                    }
                    if let urlString = info.embassy, let url = URL(string: urlString), !urlString.isEmpty {
                        Link(destination: url) {
                            Label("Find Embassy", systemImage: "building.columns")
                        }
                    }
                }
                .font(.caption)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(info.destination).font(.headline).bold()
                Text("Capital: \(info.capital ?? "-")").font(.caption)
                Text("Currency: \(info.currency ?? "-")").font(.caption)
                Spacer()
            }
            .foregroundColor(.secondary)
            
        }
        .padding()
    }
    
    private func errorContent(_ message: String) -> some View {
        VStack(alignment: .leading) {
            Text("Error for \(check.country.name)")
                .bold()
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func detailItem(title: String, value: String?) -> some View {
        if let value = value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .fontWeight(.medium)
            }
        }
    }
}
