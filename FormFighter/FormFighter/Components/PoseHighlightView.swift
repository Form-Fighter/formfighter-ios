import SwiftUI
import AVFoundation
import Vision

// Add this class before the PoseHighlightView struct
class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish()
    }
}

struct PoseHighlightView: View {
    let videoURL: URL
    let metricName: String
    let selectedSentence: String?
    
    @State private var highlightedImage: UIImage?
    @State private var isExpanded: Bool = true
    @State private var showingMetricInfo: Bool = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var phaseLabel: String?
    @State private var landmarks: [VNHumanBodyPoseObservation.JointName] = []
    @State private var highlightColor: UIColor = .red
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var landmarkPositions: [(VNHumanBodyPoseObservation.JointName, CGPoint)] = []
    @State private var isSpeaking = false
    @State private var speechDelegate: SpeechSynthesizerDelegate?
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let image = highlightedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: UIScreen.main.bounds.height * 0.7)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isExpanded.toggle()
                            }
                        }
                        .overlay(
                            GeometryReader { geometry in
                                ForEach(landmarkPositions, id: \.0) { landmark, position in
                                    Circle()
                                        .fill(Color(highlightColor.withAlphaComponent(0.5)))
                                        .frame(width: 18, height: 18)
                                        .position(
                                            x: geometry.size.width * position.x,
                                            y: geometry.size.height * position.y
                                        )
                                        .shadow(color: .black.opacity(0.5), radius: 2)
                                }
                            }
                        )
                    
                    // Info button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showingMetricInfo.toggle() }) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                } else if isLoading {
                    ProgressView()
                        .frame(height: 200)
                } else if let error = error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 200)
                }
            }
            
            // Selected sentence display
            if let sentence = selectedSentence {
                HStack {
                    Text(sentence)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(highlightColor).opacity(0.1))
                        )
                    
                    Button(action: { speakSentence(sentence) }) {
                        Image(systemName: isSpeaking ? "stop.circle" : "speaker.wave.2")
                            .foregroundColor(Color(highlightColor))
                            .overlay(
                                Group {
                                    if isSpeaking {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(highlightColor)))
                                            .scaleEffect(0.5)
                                    }
                                }
                            )
                    }
                }
                .padding(.top, 8)
            }
            
            // Metric info overlay
            if showingMetricInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text(metricName.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.headline)
                    Text("Tap image to expand/collapse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: selectedSentence) { newSentence in
            if let sentence = newSentence {
                Task {
                    do {
                        try await generateHighlightedFrame(sentence: sentence)
                    } catch {
                        print("🔴 Error generating frame: \(error)")
                    }
                }
            }
        }
        .onAppear {
            if let sentence = selectedSentence {
                Task {
                    do {
                        try await generateHighlightedFrame(sentence: sentence)
                    } catch {
                        print("🔴 Error generating frame: \(error)")
                    }
                }
            }
        }
    }
    
    private func generateHighlightedFrame(sentence: String) async throws {
        let (detectedLandmarks, highlightType, frameTime) = PoseHighlightMapping.analyzeMetric(metricName: metricName, sentence: sentence)
        
        // Get frame from video
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: frameTime.lowerBound + (frameTime.upperBound - frameTime.lowerBound) / 2, preferredTimescale: 600)
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let uiImage = UIImage(cgImage: cgImage)
        
        // Run Vision on full image
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let observation = request.results?.first as? VNHumanBodyPoseObservation else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No pose detected"])
        }
        
        // Get recognized points
        let recognizedPoints = try observation.recognizedPoints(.all)
        
        // Store landmarks and color
        landmarks = detectedLandmarks
        highlightColor = highlightType.color
        highlightedImage = uiImage
        
        // Store points with flipped y coordinates (Vision -> SwiftUI conversion)
        landmarkPositions = detectedLandmarks.compactMap { landmark -> (VNHumanBodyPoseObservation.JointName, CGPoint)? in
            guard let point = recognizedPoints[landmark],
                  point.confidence > 0.3 else { return nil }
            
            // Flip the y coordinate (1 - y) to convert from Vision (bottom-left) to SwiftUI (top-left) coordinate space
            return (landmark, CGPoint(x: point.location.x, y: 1 - point.location.y))
        }
    }
    
    private func speakSentence(_ sentence: String) {
        if isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            return
        }
        
        isSpeaking = true
        let utterance = AVSpeechUtterance(string: sentence)
        
        // Get all available voices and find a male English voice
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if let maleVoice = voices.first(where: { 
            $0.identifier.contains("com.apple.voice.premium.en-US.Daniel") 
        }) {
            utterance.voice = maleVoice
        } else if let defaultMaleVoice = voices.first(where: { 
            $0.gender == .male && $0.language.starts(with: "en") 
        }) {
            utterance.voice = defaultMaleVoice
        }
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 0.9
        utterance.volume = 0.8
        
        // Create delegate and store it
        speechDelegate = SpeechSynthesizerDelegate { [self] in
            isSpeaking = false
        }
        speechSynthesizer.delegate = speechDelegate
        
        speechSynthesizer.speak(utterance)
    }
} 
