//import SwiftUI
//
//struct ResultsView: View {
//    @EnvironmentObject var userManager: UserManager
//    @Environment(\.dismiss) var dismiss
//    @State var meal: Meal
//    @State var startAnimations = false
//    
//    var body: some View {
//        VStack {
//            HStack {
//                Spacer()
//                
//                Button {
//                    dismiss()
//                } label: {
//                    Image(systemName: "xmark")
//                        .font(.system(.title2, weight: .semibold))
//                }
//            }
//            .padding([.horizontal, .top])
//            
//            VStack(spacing: 24) {
//                Text(meal.name)
//                    .font(.special(.title, weight: .bold))
//                    .lineLimit(2)
//                
//                meal.image
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 200, height: 200)
//                    .clipped()
//                    .clipShape(Circle())
//                    
//                    
//                    .shadow(radius: 10)
//            }
//            .padding([.horizontal, .top])
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//            
//            Text("\(meal.totalCaloriesEstimation) kcal")
//                .font(.special(.largeTitle, weight: .black))
//                .foregroundStyle(.ruby.gradient)
//                .scaleEffect(startAnimations ? 1.2 : 0.4)
//            
//            MacroBarsView(meal: meal)
//                .padding()
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(.customBackground)
//        .onAppear {
//            DispatchQueue.main.async {
//                withAnimation(.snappy(duration: 1).delay(0.4)) {
//                    startAnimations = true
//                }
//            }
//        }
//        .safeAreaInset(edge: .bottom, content: {
//            RoundedButton(title: "Accept") {
//                dismiss()
//            }
//            .padding(.horizontal)
//        })
//    }
//}
//
//#Preview {
//    ResultsView(meal: Meal.mockMeal)
//        .environmentObject(UserManager.shared)
//}

import SwiftUI
import AVFoundation
import Vision
import Photos
import AVKit

struct ResultsView: View {
    var videoURL: URL
    @Environment(\.dismiss) var dismiss // To dismiss the view when buttons are pressed
    
    @State private var player: AVPlayer
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        self._player = State(initialValue: AVPlayer(url: videoURL)) // Initialize the player with the video
    }
    
    var body: some View {
        ZStack {
            // Full screen video
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    player.play() // Automatically play when the view appears
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                        player.seek(to: .zero) // Rewind to the beginning
                        player.play() // Play in a loop
                    }
                }
                .onDisappear {
                    // Delete the temporary video file when the view disappears
                    deleteTemporaryVideo()
                }
            
            // Buttons for discard and save
            VStack {
                Spacer()
                HStack {
                    Button("Discard") {
                        dismiss() // Dismiss the view
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    
                    Button("Save") {
                        dismiss() // Dismiss is used here as an example
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.bottom, 30) // Bottom padding for the buttons
            }
        }
        .navigationBarBackButtonHidden(true) // Hide the back button
    }
    
    func deleteTemporaryVideo() {
        do {
            try FileManager.default.removeItem(at: videoURL)
            print("Temporary video file deleted.")
        } catch {
            print("Error deleting video file: \(error)")
        }
    }
}
