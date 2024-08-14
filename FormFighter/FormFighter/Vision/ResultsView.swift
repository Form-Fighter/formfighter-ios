import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss
    @State var meal: Meal
    @State var startAnimations = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(.title2, weight: .semibold))
                }
            }
            .padding([.horizontal, .top])
            
            VStack(spacing: 24) {
                Text(meal.name)
                    .font(.special(.title, weight: .bold))
                    .lineLimit(2)
                
                meal.image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipped()
                    .clipShape(Circle())
                    
                    
                    .shadow(radius: 10)
            }
            .padding([.horizontal, .top])
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            Text("\(meal.totalCaloriesEstimation) kcal")
                .font(.special(.largeTitle, weight: .black))
                .foregroundStyle(.ruby.gradient)
                .scaleEffect(startAnimations ? 1.2 : 0.4)
            
            MacroBarsView(meal: meal)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.customBackground)
        .onAppear {
            DispatchQueue.main.async {
                withAnimation(.snappy(duration: 1).delay(0.4)) {
                    startAnimations = true
                }
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            RoundedButton(title: "Accept") {
                dismiss()
            }
            .padding(.horizontal)
        })
    }
}

#Preview {
    ResultsView(meal: Meal.mockMeal)
        .environmentObject(UserManager.shared)
}
