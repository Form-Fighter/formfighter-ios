import SwiftUI
import Lottie

struct VisionView: View {
    @AppStorage("gptLanguage") var gptLanguage: GPTLanguage = .english
    @StateObject var vm: VisionVM
    @EnvironmentObject var userManager: UserManager
    @State var isSelectingImage = false
    @State var isCameraPresented = false
    @State var isLibraryPresented = false
    @State var isShowingPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack {
                        addImageView
                            .padding(.vertical)
                        
                        // MARK: - Example of how can you handle the freemium part of the app
                        // allowing free credits to try it
                        if !userManager.isSubscriptionActive {
                            freemiumView
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollBounceBehavior(.basedOnSize)
                
                if vm.isAnalyzing {
                    VStack(spacing: 0) {
                        Text("Analyzing image...")
                            .font(.special(.title, weight: .bold))
                            .foregroundStyle(.brand)
                            .multilineTextAlignment(.center)
                            .padding()
                        LottieView(animation: .named("sandwich-loading"))
                            .playing()
                            .looping()
                            .frame(maxHeight: 300)
                        Text("This process may take up to a couple of minutes. Thank you for your patience!")
                            .font(.special(.title3, weight: .medium))
                            .foregroundStyle(.brand)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.customBackground)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.customBackground)
            .confirmationDialog("Choose picture", isPresented: $isSelectingImage) {
                VStack {
                    Button("Camera") {
                        isCameraPresented.toggle()
                        vm.selectedImage = nil
                    }
                    Button("Photo Library") { isLibraryPresented.toggle() }
                }
            } message: {
                Text("Choose Image Source")
                    .font(.special(.body, weight: .medium))
            }
            .sheet(isPresented: $isCameraPresented, onDismiss: {
                vm.saveImageToLibrary()
            }) {
                ImagePicker(selectedImage: $vm.selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $isLibraryPresented, onDismiss: {
                
            }) {
                ImagePicker(selectedImage: $vm.selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $vm.isPresentingResults, onDismiss: {
                
            }) {
                if let analysis = vm.mealResponse, let mealPicture = vm.selectedImage {
                    let meal = Meal(with: analysis, image: Image(uiImage: mealPicture))
                    ResultsView(meal: meal)
                }
            }
            .fullScreenCover(isPresented: $isShowingPaywall, content: {
                PaywallView()
            })
            .alert(isPresented: $vm.isShowingError) {
                Alert(title: Text("Oops! Something went wrong."), message: Text(vm.errorMessage), dismissButton: .default(Text("OK")))
            }
            .safeAreaInset(edge: .bottom) {
                if !vm.isAnalyzing {
                    Button {
                        Haptic.shared.mediumImpact()
                        
                        // MARK: - Example of how can we deal with the freemium part of the app.
                        // In this button we handle if the user can use a free credit. Otherwise we
                        // present the Paywall to allow purchase the premium features.
                        Task {
                            if vm.canAnalyze() {
                                Tracker.createAnalysis(language: gptLanguage)
                                await vm.analyzeMeal()
                                // vm.dummyAnalyze()
                            } else {
                                Tracker.viewedPaywall(onboarding: false)
                                isShowingPaywall.toggle()
                            }
                        }
                    } label: {
                        HStack {
                            if vm.isAnalyzing {
                                ProgressView()
                                    .tint(.brand)
                            } else {
                                Text("Analyze")
                                    .font(.special(.title3, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 56)
                        .background(vm.isAnalyzing ? .gray : .brand)
                        .cornerRadius(16)
                    }
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 56)
                    .padding()
                    .disabled(vm.selectedImage == nil || vm.isAnalyzing)
                    .opacity(vm.selectedImage == nil ? 0 : 1)
                }
            }
            .toolbar(vm.isAnalyzing ? .hidden : .automatic, for: .tabBar)
        }
    }
    
    var addImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 80)
                .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [10,5]))
            
            if vm.selectedImage == nil {
                ZStack {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.brand.opacity(0.2))
                            .frame(maxWidth: 200)
                            .offset(y: -10)
                        
                        Button {
                            Haptic.shared.lightImpact()
                            isSelectingImage.toggle()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.white, .brand)
                                .frame(maxWidth: 50)
                        }
                        .offset(x: 10 ,y: 10)
                    }
                    .onTapGesture {
                        Haptic.shared.lightImpact()
                        isSelectingImage.toggle()
                    }
                    
                    
                    Button {
                        Haptic.shared.notificationOccurred(type: .success)
                        withAnimation(.bouncy(duration: 0.3), {
                            vm.pasteImage()
                        })
                    } label: {
                        Text("📋 Paste")
                            .font(.special(.title3, weight: .medium))
                    }
                    .frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .top)
                    .foregroundStyle(.brand)
                    .padding(.vertical, 20)
                    
                    
                    Text("Select Meal")
                        .font(.special(.body, weight: .medium))
                        .frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .bottom)
                        .padding(.vertical, 24)
                        .onTapGesture {
                            Haptic.shared.lightImpact()
                            isSelectingImage.toggle()
                        }
                }
            } else {
                Button {
                    Haptic.shared.notificationOccurred(type: .error)
                    withAnimation {
                        self.vm.selectedImage = nil
                    }
                } label: {
                    Text("Delete")
                        .font(.special(.title3, weight: .medium))
                        .foregroundStyle(.ruby)
                }
                .frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .bottom)
                .padding(6)
                
                Image(uiImage: vm.selectedImage ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 42)
                    .onTapGesture {
                        isSelectingImage.toggle()
                    }
            }
        }
        .frame(height: 350)
    }
    
    var freemiumView: some View {
        Group {
            Text("You have \(vm.freeCredits) free analysis left")
                .font(.special(.body, weight: .semibold))
            Button {
                Haptic.shared.mediumImpact()
                Tracker.tappedUnlockPremium()
                isShowingPaywall.toggle()
            } label : {
                PremiumBannerView(color: .ruby)
                    .frame(minHeight: 80, maxHeight: 96)
            }
        }
    }
}

#Preview {
    VisionView(vm: VisionVM(isAnalyzing: false, analyzeService: AnalyzeMealVisionService()))
        .environmentObject(UserManager.shared)
}
