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
    @Environment(\.dismiss) var dismiss // Para hacer dismiss al presionar los botones
    
    @State private var player: AVPlayer
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        self._player = State(initialValue: AVPlayer(url: videoURL)) // Inicializar el player con el video
    }
    
    var body: some View {
        ZStack {
            // Video en pantalla completa
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    player.play() // Reproducir automáticamente al aparecer
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                        player.seek(to: .zero) // Volver al inicio
                        player.play() // Reproducir en bucle
                    }
                }
            
            // Botones para descartar y guardar
            VStack {
                Spacer()
                HStack {
                    Button("Discard") {
                        dismiss() // Hacer dismiss de la vista
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    
                    Button("Save") {
                        dismiss() // También se usa dismiss, solo para ejemplo
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.bottom, 30) // Espacio inferior para los botones
            }
        }
        .navigationBarBackButtonHidden(true) // Ocultar el botón de atrás
    }
    
}
