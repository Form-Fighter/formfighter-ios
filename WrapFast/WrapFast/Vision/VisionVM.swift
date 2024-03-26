import UIKit
import SwiftUI
import KeychainSwift

class VisionVM: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isAnalyzing = false
    @Published var isPresentingResults = false
    @Published var errorMessage: LocalizedStringKey = ""
    @Published var isShowingError = false
    let keychain = KeychainSwift()
    let authBackendService = AuthBackendService()
    let analyzeService: AnalyzeMealProtocol
    let userManager = UserManager.shared
    var mealResponse: MealVisionResponse?
    
    var freeCredits: Int {
        KeychainManager.shared.getFreeExtraCredits()
    }
    
    init(selectedImage: UIImage? = nil,
         isAnalyzing: Bool = false,
         isPresentingResults: Bool = false,
         errorMessage: LocalizedStringKey = "",
         isShowingError: Bool = false,
         mealResponse: MealVisionResponse? = nil,
         // By default, we instantiate the backend Service.
         // If you want to use AI Proxy, override this and inject the AnalyzeMealAIProxyService (they conform to the same AnalyzeMealProtocol)
         analyzeService: AnalyzeMealProtocol = AnalyzeMealVisionService()
    ) {
        self.selectedImage = selectedImage
        self.isAnalyzing = isAnalyzing
        self.isPresentingResults = isPresentingResults
        self.errorMessage = errorMessage
        self.isShowingError = isShowingError
        self.mealResponse = mealResponse
        self.analyzeService = analyzeService
        
        Task {
            await fetchBackendAuthIfNecessary()
            try? await userManager.fetchAllData()
        }
    }
    
    // MARK: - Backend Authentication. It is needed to do this once from our app.
    // We need to authenticate with our backend fetching a secret token, storing it in the Keychain.
    // It is necessary to do this once in the lifetime of the app.
    // I decided to make the request in this VM because is the first screen shown once the user is signed up.
    // You can move it to anywhere in your app, depending your needs.
    
    private func fetchBackendAuthIfNecessary() async {
        let key = keychain.get(Const.Keychain.tokenKey)
        if key == nil || key == "" {
            let string = await authBackendService.fetchValue()
            keychain.set(string, forKey: Const.Keychain.tokenKey)
            Logger.log(message: "Request auth backend secret complete and stored in keychain", event: .debug)
        }
    }
    
    func analyzeMeal() async {
        Logger.log(message: "Analyzing image...", event: .debug)
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
        
        guard let imageString = selectedImage?.resized().toBase64String() else {
            Logger.log(message: "Error converting image or image is nil", event: .error)
            DispatchQueue.main.async {
                self.isAnalyzing = false
            }
            return
        }
        
        var gptLanguage: GPTLanguage = .english
        
        if let storedLanguage = UserDefaults.standard.string(forKey: "gptLanguage") {
            gptLanguage = GPTLanguage(rawValue: storedLanguage) ?? .english
        }
        
        let analysisRequest = MealVisionRequestModel(image: imageString, language: gptLanguage.rawValue)
        
        do {
            let analyzeResponse = try await analyzeService.analyzeMeal(with: analysisRequest)
            DispatchQueue.main.async {
                if !self.userManager.isSubscriptionActive {
                    self.useFreeCredit()
                }
                self.mealResponse = analyzeResponse
                self.isPresentingResults = true
                Logger.log(message: "Analyzed meal completed", event: .debug)
            }
            
            dump(analyzeResponse)
            
            DispatchQueue.main.async {
                self.isAnalyzing = false
            }
        } catch {
            Logger.log(message: error.localizedDescription, event: .error)
            DispatchQueue.main.async {
                self.errorMessage = "Please try again later. If the issue continues, consider using a different picture. Occasionally, GPT-4 Vision AI might encounter difficulties interpreting certain images or requests."
                self.isShowingError.toggle()
                self.isAnalyzing = false
            }
        }
        
    }
    
    func useFreeCredit() {
        if freeCredits > 0 {
            KeychainManager.shared.setFreeCredits(with: freeCredits - 1)
        }
    }
    
    func pasteImage() {
        let pastedBoard = UIPasteboard.general
        if let pastedImage = pastedBoard.image {
            Tracker.pasted()
            DispatchQueue.main.async {
                self.selectedImage = pastedImage
            }
        }
    }
    
    func saveImageToLibrary() {
        if let selectedImage {
            UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
        }
    }
    
    // MARK: - Example of handling wether the user can request a call to the API
    // or not when pressing the button.
    // If you don't want to control this, just return always TRUE.
    func canAnalyze() -> Bool {
        userManager.isSubscriptionActive || freeCredits > 0
    }
}

// MARK: - DEBUG
extension VisionVM {
    
    // Function to test a fake analysis to debug the flow of the result view appearance.
    func dummyAnalyze() {
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            self.isAnalyzing = false
        })
    }
}
