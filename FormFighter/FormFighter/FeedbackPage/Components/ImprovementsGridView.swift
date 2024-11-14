import SwiftUI
struct ImprovementsGridView: View {
    @Binding var selectedImprovements: [String]
    let improvements: [String]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(improvements, id: \.self) { improvement in
                Button(action: {
                    if selectedImprovements.contains(improvement) {
                        selectedImprovements.removeAll { $0 == improvement }
                    } else {
                        selectedImprovements.append(improvement)
                    }
                }) {
                    Text(improvement)
                        .font(.subheadline)
                        .foregroundColor(selectedImprovements.contains(improvement) ? .white : .primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedImprovements.contains(improvement) ? Color.red : Color.gray.opacity(0.1))
                        )
                }
            }
        }
        .padding(.horizontal)
    }
} 
