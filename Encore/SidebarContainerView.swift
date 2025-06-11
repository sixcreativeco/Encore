import SwiftUI

struct SidebarContainerView: View {
    @State private var isSidebarVisible = true
    @State private var selectedTab: String = "Dashboard"
    @ObservedObject private var syncManager = OfflineSyncManager.shared
    @ObservedObject var appState: AppState

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                if isSidebarVisible {
                    VStack(alignment: .leading) {
                        Text("ENCORE")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.top, 32)

                        Spacer().frame(height: 40)

                        VStack(alignment: .leading, spacing: 12) {
                            SidebarLabel(title: "Dashboard", isSelected: selectedTab == "Dashboard") {
                                selectedTab = "Dashboard"
                            }
                            SidebarLabel(title: "Tours", isSelected: selectedTab == "Tours") {
                                selectedTab = "Tours"
                            }
                            SidebarLabel(title: "Connections", isSelected: selectedTab == "Connections") {
                                selectedTab = "Connections"
                            }
                            SidebarLabel(title: "Team", isSelected: selectedTab == "Team") {
                                selectedTab = "Team"
                            }
                            SidebarLabel(title: "Flights", isSelected: selectedTab == "Flights") {
                                selectedTab = "Flights"
                            }
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                            Button(action: {
                                selectedTab = "NewTour"
                            }) {
                                Text("Add Tour")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(6)
                            }

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(syncManager.isOnline ? Color.green : Color.gray)
                                    .frame(width: 10, height: 10)

                                Text(syncManager.isOnline ? "Online" : "Offline")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.bottom, 20)

                        Button(action: {
                            AuthManager.shared.signOut(appState: appState)
                            appState.isLoggedIn = false
                        }) {
                            Text("Sign Out")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                    .frame(width: 240)
                    .background(Color.gray.opacity(0.2))
                }

                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                isSidebarVisible.toggle()
                            }
                        }) {
                            Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()

                        Spacer()
                    }

                    Group {
                        switch selectedTab {
                        case "Dashboard":
                            Text("Dashboard View").frame(maxWidth: .infinity, maxHeight: .infinity)
                        case "Tours":
                            TourListView().frame(maxWidth: .infinity, maxHeight: .infinity)
                        case "Connections":
                            Text("Connections View").frame(maxWidth: .infinity, maxHeight: .infinity)
                        case "Team":
                            Text("Team View").frame(maxWidth: .infinity, maxHeight: .infinity)
                        case "NewTour":
                            NewTourFlowView().frame(maxWidth: .infinity, maxHeight: .infinity)
                        default:
                            Text("Unknown")
                        }
                    }
                }
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
