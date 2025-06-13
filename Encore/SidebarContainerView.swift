import SwiftUI

struct SidebarContainerView: View {
    @StateObject private var syncManager = OfflineSyncManager.shared
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var overrideColorScheme: ColorScheme? = nil
    @State private var isSidebarVisible = true

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                if isSidebarVisible { sidebar }
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { withAnimation { isSidebarVisible.toggle() } }) {
                            Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        Spacer()
                    }
                    contentView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .preferredColorScheme(overrideColorScheme ?? systemColorScheme)
    }

    private var sidebar: some View {
        VStack(alignment: .leading) {
            logoSection
                .padding(.top, 32)
            Spacer().frame(height: 40)

            VStack(alignment: .leading, spacing: 12) {
                SidebarLabel(title: "Dashboard", isSelected: appState.selectedTab == "Dashboard") { appState.selectedTab = "Dashboard"; appState.selectedTour = nil }
                SidebarLabel(title: "Tours", isSelected: appState.selectedTab == "Tours") { appState.selectedTab = "Tours"; appState.selectedTour = nil }
                SidebarLabel(title: "Contacts", isSelected: appState.selectedTab == "Contacts") { appState.selectedTab = "Contacts"; appState.selectedTour = nil }
                SidebarLabel(title: "Team", isSelected: appState.selectedTab == "Team") { appState.selectedTab = "Team"; appState.selectedTour = nil }
                SidebarLabel(title: "Flights", isSelected: appState.selectedTab == "Flights") { appState.selectedTab = "Flights"; appState.selectedTour = nil }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                addTourButton
                HStack(spacing: 6) {
                    Circle().fill(syncManager.isOnline ? Color.green : Color.gray).frame(width: 10, height: 10)
                    Text(syncManager.isOnline ? "Online" : "Offline")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }.padding(.top, 4)
            }
            .padding(.bottom, 20)

            Button(action: { AuthManager.shared.signOut(appState: appState) }) {
                Text("Sign Out").font(.footnote).foregroundColor(.red)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(width: 240)
        .background(Color.gray.opacity(0.2))
    }

    private var logoSection: some View {
        Button(action: { toggleColorMode() }) {
            Image("EncoreLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .foregroundColor(currentLogoColor)
                .padding(.bottom, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // ✅ THIS IS THE ONLY CHANGE YOU NEEDED
    private var currentLogoColor: Color {
        let activeColorScheme = overrideColorScheme ?? systemColorScheme
        return activeColorScheme == .dark
            ? Color(red: 237/255, green: 237/255, blue: 237/255) // #EDEDED
            : Color(red: 31/255, green: 31/255, blue: 31/255)     // #1F1F1F
    }

    private var addTourButton: some View {
        Button(action: { appState.selectedTab = "NewTour"; appState.selectedTour = nil }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Tour")
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(.black)
    }

    private func toggleColorMode() {
        if overrideColorScheme == .dark {
            overrideColorScheme = .light
        } else {
            overrideColorScheme = .dark
        }
    }

    @ViewBuilder
    private func contentView() -> some View {
        if let tour = appState.selectedTour {
            TourDetailView(tour: tour).environmentObject(appState)
        } else {
            switch appState.selectedTab {
            case "Dashboard": Text("Dashboard View")
            case "Tours": TourListView(onTourSelected: { appState.selectedTour = $0 }).environmentObject(appState)
            case "Contacts": ContactsView(userID: appState.userID ?? "")
            case "Team": Text("Team View")
            case "Flights": Text("Flights View")
            case "NewTour": NewTourFlowView().environmentObject(appState)
            default: Text("Unknown")
            }
        }
    }
}

struct SidebarLabel: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 19, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
