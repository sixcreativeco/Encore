import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct TourDetailView: View {
    var tour: TourModel
    @EnvironmentObject var appState: AppState

    @State private var offsetY: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                crewSection
                showsSection
            }
            .padding()
        }
        .ignoresSafeArea()
        .onAppear {
            loadPosterOffset()
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
                        .frame(width: geo.size.width, height: 300)
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
                    Color.gray.frame(height: 300)
                }
            }
            .frame(height: 300)

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
        .frame(height: 300)
        .background(Color.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 10)
        .padding(.top, 48)  // <-- Push it down to avoid safe area cut off
    }

    // MARK: Crew Section
    private var crewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crew")
                .font(.headline)
            Text("Tour Manager: Cam Noble")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
