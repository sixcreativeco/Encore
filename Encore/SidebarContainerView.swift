import SwiftUI

struct SidebarContainerView: View {
    @StateObject private var syncManager = OfflineSyncManager.shared
    @EnvironmentObject var appState: AppState
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
    }

    private var sidebar: some View {
        VStack(alignment: .leading) {
            Text("ENCORE")
                .font(.system(size: 18, weight: .bold))
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
                Button(action: { appState.selectedTab = "NewTour"; appState.selectedTour = nil }) {
                    Text("Add Tour")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(6)
                }
                HStack(spacing: 6) {
                    Circle().fill(syncManager.isOnline ? Color.green : Color.gray).frame(width: 10, height: 10)
                    Text(syncManager.isOnline ? "Online" : "Offline")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }.padding(.top, 4)
            }.padding(.bottom, 20)

            Button(action: { AuthManager.shared.signOut(appState: appState) }) {
                Text("Sign Out").font(.footnote).foregroundColor(.red)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(width: 240)
        .background(Color.gray.opacity(0.2))
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
