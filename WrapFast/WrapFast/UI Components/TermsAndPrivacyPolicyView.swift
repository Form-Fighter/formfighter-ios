import SwiftUI

struct TermsAndPrivacyPolicyView: View {
    var body: some View {
        HStack {
            Button {
                Haptic.shared.lightImpact()
                if let url =  Const.Purchases.termsOfServiceLink {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Terms of Service")
                    .font(.special(.footnote, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Text("·")
                .font(.special(.body, weight: .semibold))
                .frame(alignment: .center)
            
            Button {
                Haptic.shared.lightImpact()
                if let url =  Const.Purchases.privacyPolicyLink {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Privacy Policy")
                    .font(.special(.footnote, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.brand)
    }
}

#Preview {
    TermsAndPrivacyPolicyView()
}
