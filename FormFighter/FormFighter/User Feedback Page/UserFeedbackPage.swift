import SwiftUI
import WishKit

struct UserFeedbackView: View {
    @State private var feedbackText: String = ""
    @State private var selectedFeedback: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Heading Text
            Text("How was your experience?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Is this the feedback you expected?")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
            
            // Feedback Buttons
            HStack(spacing: 20) {
                Spacer()
                
                Button(action: {
                   // Tracker.tappedSuggestFeatures()
                    showWishKit()
                    selectedFeedback = "Amazing"
                }) {
                    VStack {
                        Text("🤩")
                            .font(.largeTitle)
                        Text("Amazing")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(selectedFeedback == "Amazing" ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                  //  Tracker.tappedSuggestFeatures()
                    showWishKit()
                    selectedFeedback = "Okay"
                }) {
                    VStack {
                        Text("🙂")
                            .font(.largeTitle)
                        Text("Okay")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(selectedFeedback == "Okay" ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                   // Tracker.tappedSuggestFeatures()
                    showWishKit()
                    selectedFeedback = "Not So Good"
                }) {
                    VStack {
                        Text("🙁")
                            .font(.largeTitle)
                        Text("Not Okay")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(selectedFeedback == "Not So Good" ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.vertical)
            
            // Text Field for Detailed Feedback
            Text("Tell us more")
                .font(.headline)
                .padding(.top)
          Text("Please type at least 15 characters")
                .font(.subheadline)
            
            TextEditor(text: $feedbackText)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                .frame(height: 200)
            
            if feedbackText.count >= 10 {
                Button(action: {
                    // Action for next button
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            WishKit.view
                .onAppear {
                    Tracker.tappedSuggestFeatures()
                }
        }
    }
    
    // Show WishKit Feedback Page
    private func showWishKit() {
        WishKit.view
    }
}

struct UserFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        UserFeedbackView()
    }
}
