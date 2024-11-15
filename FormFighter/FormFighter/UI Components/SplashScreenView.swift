import SwiftUI
import WebKit

struct SplashScreenView: View {
    @State private var isLoading = true
    let gifDuration: Double = 2.0  // Adjust to match your GIF duration
    
    var body: some View {
        ZStack {
            // Ensure black background matches Launch Screen
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            GIFView(gifName: "splashscreen")
                .edgesIgnoringSafeArea(.all)
                .opacity(isLoading ? 0 : 1) // Start invisible and fade in
                .animation(.easeIn(duration: 0.2), value: isLoading)
        }
        .onAppear {
            // Immediately start loading the GIF
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
}

struct GIFView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .black // Match Launch Screen
        webView.isOpaque = true
        webView.scrollView.isScrollEnabled = false
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let gifPath = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let gifData = try? Data(contentsOf: URL(fileURLWithPath: gifPath)),
           let base64String = gifData.base64EncodedString() as String? {
            
            let html = """
            <html>
            <head>
                <style>
                    body {
                        margin: 0;
                        padding: 0;
                        background: black;
                    }
                    .container {
                        width: 100vw;
                        height: 100vh;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        background: black;
                    }
                    img {
                        width: 100%;
                        height: 100%;
                        object-fit: contain;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <img src="data:image/gif;base64,\(base64String)" autoplay>
                </div>
            </body>
            </html>
            """
            
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
} 