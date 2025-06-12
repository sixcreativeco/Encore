import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct TourListView: View {
    @EnvironmentObject var appState: AppState
    var onTourSelected: ((TourModel) -> Void)? = nil

    @State private var tours: [TourModel] = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(tours) { tour in
                    Button(action: {
                        onTourSelected?(tour)
                    }) {
                        HStack(spacing: 16) {
                            if let url = URL(string: tour.posterURL ?? "") {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 80)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(tour.name)
                                    .font(.headline)
                                Text(tour.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .onAppear {
            loadTours()
        }
    }

    private func loadTours() {
        guard let userID = appState.userID else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userID).collection("tours")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, _ in
                self.tours = snapshot?.documents.compactMap { TourModel(from: $0) } ?? []
            }
    }
}
