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
                floatingSidebar
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { withAnimation { isSidebarVisible.toggle() } }) {
                            Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.leading, 20)
                        .padding(.top, 30)
                        Spacer()
                    }
                    contentView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.windowBackgroundColor))
                }
            }
        }
        .preferredColorScheme(overrideColorScheme ?? systemColorScheme)
        .background(Color(.windowBackgroundColor))
    }

    @ViewBuilder
    private func contentView() -> some View {
        VStack(spacing: 0) {
            if let show = appState.selectedShow {
                ShowDetailView(show: show, userID: appState.userID ?? "", tourID: appState.selectedTour?.id ?? "")
                    .environmentObject(appState)
            } else if let tour = appState.selectedTour {
                TourDetailView(tour: tour)
                    .environmentObject(appState)
            } else {
                switch appState.selectedTab {
                case "Dashboard": Text("Dashboard View")
                case "Tours": TourListView(onTourSelected: { appState.selectedTour = $0 }).environmentObject(appState)
                case "Database": DatabaseView(userID: appState.userID ?? "")
                case "Team": Text("Team View")
                case "MyAccount": MyAccountView().environmentObject(appState)
                case "NewTour": NewTourFlowView().environmentObject(appState)
                default: Text("Unknown")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var floatingSidebar: some View {
        VStack(alignment: .center, spacing: 0) {
            if isSidebarVisible {
                expandedSidebarContent
            } else {
                collapsedSidebarContent
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(width: isSidebarVisible ? 220 : 72)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(currentSidebarBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.leading, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .animation(.easeInOut(duration: 0.25), value: isSidebarVisible)
    }

    private var currentSidebarBackground: Color {
        let activeColorScheme = overrideColorScheme ?? systemColorScheme
        return activeColorScheme == .dark
            ? Color(red: 47/255, green: 56/255, blue: 60/255)
            : Color(red: 178/255, green: 203/255, blue: 206/255)
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
                SidebarLabel(icon: "calendar", title: "Tours", isSelected: appState.selectedTab == "Tours", spacing: 16) {
                    appState.selectedTab = "Tours"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarLabel(icon: "book.fill", title: "Database", isSelected: appState.selectedTab == "Database", spacing: 16) {
                    appState.selectedTab = "Database"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarLabel(icon: "person.2.fill", title: "Team", isSelected: appState.selectedTab == "Team", spacing: 15.2) {
                    appState.selectedTab = "Team"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarLabel(icon: "person.crop.circle", title: "My Account", isSelected: appState.selectedTab == "MyAccount", spacing: 25.2) {
                    appState.selectedTab = "MyAccount"; appState.selectedTour = nil; appState.selectedShow = nil
                }
            }
            .padding(.leading, 30)

            Spacer()

            VStack(alignment: .leading, spacing: 10) {
                addTourButtonExpanded
                HStack(spacing: 6) {
                    Circle().fill(syncManager.isOnline ? Color.green : Color.gray).frame(width: 10, height: 10)
                    Text("Online")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }.padding(.top, 4)
            }
            .padding(.bottom, 20)
            .padding(.leading, 30)
        }
        .padding(.horizontal, 20)
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
                SidebarIcon(icon: "book.fill", isSelected: appState.selectedTab == "Database") {
                    appState.selectedTab = "Database"; appState.selectedTour = nil; appState.selectedShow = nil
                }
                SidebarIcon(icon: "person.2.fill", isSelected: appState.selectedTab == "Team") {
                    appState.selectedTab = "Team"; appState.selectedTour = nil; appState.selectedShow = nil
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
        .frame(maxWidth: .infinity)
    }

    private var logoSectionExpanded: some View {
        Button(action: { toggleColorMode() }) {
            Image("EncoreLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .foregroundColor(currentLogoColor)
                .padding(.top, 10)
                .padding(.bottom, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var logoSectionCollapsed: some View {
        Button(action: { toggleColorMode() }) {
            Image("EncoreE")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(currentLogoColor)
                .padding(.top, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var currentLogoColor: Color {
        let activeColorScheme = overrideColorScheme ?? systemColorScheme
        return Color(red: 237/255, green: 237/255, blue: 237/255)
    }

    private var addTourButtonExpanded: some View {
        Button(action: { appState.selectedTab = "NewTour"; appState.selectedTour = nil; appState.selectedShow = nil }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Tour").fontWeight(.semibold)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .frame(width: 190)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(.black)
        .padding(.trailing, 30)
    }

    private var addTourButtonCollapsed: some View {
        Button(action: { appState.selectedTab = "NewTour"; appState.selectedTour = nil; appState.selectedShow = nil }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18))
                .padding(10)
                .background(Color.white)
                .clipShape(Circle())
                .foregroundColor(.black)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func toggleColorMode() {
        if overrideColorScheme == .dark {
            overrideColorScheme = .light
        } else {
            overrideColorScheme = .dark
        }
    }
}

struct SidebarLabel: View {
    let icon: String
    let title: String
    let isSelected: Bool
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
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SidebarIcon: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}
