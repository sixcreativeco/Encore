import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct TourDetailView: View {
    var tour: TourModel
    @EnvironmentObject var appState: AppState

    @State private var offsetY: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                        .frame(height: geometry.size.width > 800 ? 400 : 300)

                    HStack(alignment: .top, spacing: 24) {
                        crewSection
                            .frame(maxWidth: geometry.size.width > 1000 ? 300 : .infinity, alignment: .leading)

                        showsSection
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .ignoresSafeArea()
            .onAppear {
                loadPosterOffset()
            }
        }
    }

    // MARK: Header Section (Hero Card)
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                if let posterURL = tour.posterURL, let url = URL(string: posterURL) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .offset(y: offsetY)
                        .gesture(
                            DragGesture().onChanged { value in
                                offsetY = value.translation.height
                            }
                            .onEnded { _ in savePosterOffset() }
                        )
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.0),
                                    Color.black.opacity(0.9)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .opacity(0.85)
                        )
                } else {
                    Color.gray.frame(height: geo.size.height)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(tour.artist)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text(tour.name)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
            }
            .padding()
        }
        .background(Color.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 10)
        .padding(.top, -10)
    }

    // MARK: Crew Section
    private var crewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crew")
                .font(.headline)
            Text("Tour Manager: Cam Noble")
        }
    }

    // MARK: Shows Section
    private var showsSection: some View {
        ShowGridView(tourID: tour.id, userID: appState.userID ?? "", artistName: tour.artist)
    }

    // MARK: Load Offset
    private func loadPosterOffset() {
        guard let userID = appState.userID else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tour.id).getDocument { document, _ in
            if let data = document?.data(), let y = data["posterOffsetY"] as? Double {
                self.offsetY = CGFloat(y)
            }
        }
    }

    // MARK: Save Offset
    private func savePosterOffset() {
        guard let userID = appState.userID else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tour.id).updateData([
            "posterOffsetY": Double(offsetY)
        ])
    }
}
