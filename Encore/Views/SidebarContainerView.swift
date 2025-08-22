import SwiftUI

struct SidebarContainerView: View {
    @StateObject private var syncManager = OfflineSyncManager.shared
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    @State private var isSidebarVisible = true
    @State private var isNotificationsPanelVisible = false

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                floatingSidebar
                
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { withAnimation { isSidebarVisible.toggle() } }) {
                            Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: { withAnimation { isNotificationsPanelVisible.toggle() } }) {
                            Image(systemName: "bell.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                                .overlay(alignment: .topTrailing) {
                                    if !appState.notifications.isEmpty {
                                        Text("\(appState.notifications.count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(5)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .offset(x: 8, y: -8)
                                    }
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.leading, 24)
                    .padding(.trailing, 40)
                    .padding(.top, 30)
                    .padding(.bottom, 10)

                    contentView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if isNotificationsPanelVisible {
                    NotificationsView(isPresented: $isNotificationsPanelVisible)
                        .frame(width: 320)
                        .transition(.move(edge: .trailing))
                }
            }
        }
    }

    @ViewBuilder
    private func contentView() -> some View {
        VStack(spacing: 0) {
            if appState.showingAbleset {
                AblesetView()
                    .environmentObject(appState)
            } else if let show = appState.selectedShow, let tour = appState.selectedTour {
                ShowDetailView(tour: tour, show: show)
                    .environmentObject(appState)
            } else if let tour = appState.selectedTour, let tourID = tour.id {
                TourDetailView(tourID: tourID)
                    .environmentObject(appState)
            } else {
                switch appState.selectedTab {
                case "Dashboard":
                    DashboardView()
                        .environmentObject(appState)
                case "Tours":
                     TourListView(onTourSelected: { tour in appState.selectedTour = tour })
                        .environmentObject(appState)
                case "Tickets":
                    TicketsDashboardView()
                        .environmentObject(appState)
                case "Database":
                     DatabaseView(userID: appState.userID ?? "")
                case "Export":
                    ExportView()
                        .environmentObject(appState)
                case "MyAccount":
                    MyAccountView().environmentObject(appState)
                case "NewTour":
                    NewTourFlowView().environmentObject(appState)
                default:
                    Text("Unknown")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var floatingSidebar: some View {
        let sidebarBackgroundColor = colorScheme == .light ?
            Color(red: 178/255, green: 203/255, blue: 206/255).opacity(0.85) :
            Color(red: 31/255, green: 46/255, blue: 52/255).opacity(0.85)
        
        return VStack(alignment: .leading, spacing: 0) {
                if isSidebarVisible {
                    expandedSidebarContent
                } else {
                    VStack(alignment: .center) {
                        collapsedSidebarContent
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .frame(width: isSidebarVisible ? 240 : 72)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.regularMaterial)
                    
                    RoundedRectangle(cornerRadius: 24)
                        .fill(sidebarBackgroundColor)
                }
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .padding(.leading, 20)
            .padding(.vertical, 20)
            .animation(.easeInOut(duration: 0.25), value: isSidebarVisible)
    }

    private var expandedSidebarContent: some View {
        VStack(alignment: .leading) {
            logoSectionExpanded
                .padding(.top, 10)
                .padding(.leading, 30)

            Spacer().frame(height: 40)

            VStack(alignment: .leading, spacing: 24) {
                SidebarLabel(icon: "rectangle.grid.2x2.fill", title: "Dashboard", isSelected: appState.selectedTab == "Dashboard", spacing: 16) {
                    appState.selectedTab = "Dashboard"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarLabel(icon: "calendar", title: "Tours", isSelected: appState.selectedTab == "Tours", spacing: 16.5) {
                    appState.selectedTab = "Tours"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarLabel(icon: "ticket.fill", title: "Tickets", isSelected: appState.selectedTab == "Tickets", spacing: 16.5) {
                    appState.selectedTab = "Tickets"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarLabel(icon: "book.fill", title: "Database", isSelected: appState.selectedTab == "Database", spacing: 16) {
                    appState.selectedTab = "Database"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarLabel(icon: "square.and.arrow.up.fill", title: "Export", isSelected: appState.selectedTab == "Export", spacing: 16) {
                    appState.selectedTab = "Export"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarLabel(icon: "person.crop.circle", title: "My Account", isSelected: appState.selectedTab == "MyAccount", spacing: 17.0) {
                    appState.selectedTab = "MyAccount"; appState.selectedTour = nil; appState.selectedShow = nil
                }
            }
            .padding(.leading, 30)

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                addTourButtonExpanded
                HStack(spacing: 6) {
                    Circle().fill(syncManager.isOnline ? Color.green : Color.gray).frame(width: 10, height: 10)
                    Text("Online").font(.footnote).foregroundColor(.secondary)
                }.padding(.top, 4)
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 30)
        }
        .padding(.vertical, 20)
    }

    private var collapsedSidebarContent: some View {
        VStack(spacing: 32) {
            logoSectionCollapsed
                .padding(.top, 10)
            VStack(spacing: 28) {
                SidebarIcon(icon: "rectangle.grid.2x2.fill", isSelected: appState.selectedTab == "Dashboard") {
                    appState.selectedTab = "Dashboard"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarIcon(icon: "calendar", isSelected: appState.selectedTab == "Tours") {
                    appState.selectedTab = "Tours"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarIcon(icon: "ticket.fill", isSelected: appState.selectedTab == "Tickets") {
                    appState.selectedTab = "Tickets"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarIcon(icon: "book.fill", isSelected: appState.selectedTab == "Database") {
                    appState.selectedTab = "Database"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarIcon(icon: "square.and.arrow.up.fill", isSelected: appState.selectedTab == "Export") {
                    appState.selectedTab = "Export"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarIcon(icon: "person.crop.circle", isSelected: appState.selectedTab == "MyAccount") {
                    appState.selectedTab = "MyAccount"; appState.selectedTour = nil; appState.selectedShow = nil
                }
            }
            Spacer()
            addTourButtonCollapsed
            Circle()
                .fill(syncManager.isOnline ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
                .padding(.bottom, 16)
        }
    }

    private var logoSectionExpanded: some View {
        Image("EncoreLogo")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 120)
            .foregroundColor(.white)
            .padding(.top, 10)
            .padding(.bottom, 20)
    }

    private var logoSectionCollapsed: some View {
        Image("EncoreE")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundColor(.white)
            .padding(.top, 4)
    }
    
    private var addTourButtonExpanded: some View {
        Button(action: { appState.selectedTab = "NewTour"; appState.selectedTour = nil; appState.selectedShow = nil }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Tour").fontWeight(.semibold)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.white.opacity(0.15))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var addTourButtonCollapsed: some View {
        Button(action: { appState.selectedTab = "NewTour"; appState.selectedTour = nil; appState.selectedShow = nil }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SidebarLabel: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var badgeCount: Int = 0
    let spacing: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: spacing) {
                Image(systemName: icon)
                    .font(.system(size: title == "My Account" ? 18 : 16))
                    .offset(y: -1)
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .bold : .regular))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SidebarIcon: View {
    let icon: String
    let isSelected: Bool
    var badgeCount: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}
