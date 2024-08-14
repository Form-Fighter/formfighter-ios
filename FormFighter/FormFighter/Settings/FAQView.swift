import SwiftUI

struct FAQView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            ScrollView {
                Text("Frequently Asked Questions for \(Const.appName)")
                    .font(.title)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Text(Const.faqMarkdown)
                .padding()
                
                TermsAndPrivacyPolicyView()
            }
        }
        .background(.customBackground)
        .toolbar(.hidden, for: .tabBar)
        .task {
            Tracker.openedFaq()
        }
    }
}

#Preview {
    FAQView()
}
