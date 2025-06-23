import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct TourHeaderView: View {
    let tour: Tour
    @EnvironmentObject var appState: AppState
    @State private var offsetY: CGFloat = 0
    @State private var initialOffsetY: CGFloat = 0
    @State private var showEditTour = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                if let posterURL = tour.posterURL, let url = URL(string: posterURL) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height + max(0, offsetY)) // Allow stretching down
                        .offset(y: offsetY)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.0),
                                    Color.black.opacity(0.9)
                                ]),
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .opacity(0.85)
                        )
                } else {
                    Color.gray
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(tour.artist)
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundColor(.white.opacity(0.9))

                Text(tour.tourName)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding()

            VStack {
                HStack {
                    Spacer()
                    Button(action: { showEditTour = true }) {
                        HStack(spacing: 6) {
                            Text("Edit Tour")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
            }
            .padding()
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 10)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let newOffsetY = initialOffsetY + value.translation.height
                    // Prevent dragging up past the initial position
                    offsetY = min(newOffsetY, 200)
                }
                .onEnded { _ in
                    initialOffsetY = offsetY
                    savePosterOffset()
                }
        )
        .onAppear {
            loadPosterOffset()
        }
        .sheet(isPresented: $showEditTour) {
            TourEditView(tour: tour).environmentObject(appState)
        }
    }

    private func savePosterOffset() {
        guard let tourID = tour.id else { return }
        let db = Firestore.firestore()
        
        // Save to the top-level 'tours' collection using merge to avoid "Not Found" errors.
        db.collection("tours")
            .document(tourID)
            .setData(["posterOffsetY": Double(offsetY)], merge: true) { error in
                if let error = error {
                    print("Error saving poster offset: \(error.localizedDescription)")
                }
            }
    }

    private func loadPosterOffset() {
        guard let tourID = tour.id else { return }
        let db = Firestore.firestore()

        // Load from the top-level 'tours' collection.
        db.collection("tours")
            .document(tourID)
            .getDocument { document, _ in
                if let data = document?.data(), let y = data["posterOffsetY"] as? Double {
                    offsetY = CGFloat(y)
                    initialOffsetY = CGFloat(y)
                }
            }
    }
}
