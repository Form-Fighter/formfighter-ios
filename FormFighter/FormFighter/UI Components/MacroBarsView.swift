import SwiftUI

struct MacroBarsView: View {
    @State var meal: Meal
    let barsMaxHeight: CGFloat = 250
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 24) {
            MacroBarView(value: meal.carbs, name: "Carbs", height: calculateBarHeight(value: meal.carbs), barColor: .red)
            MacroBarView(value: meal.proteins, name: "Proteins", height: calculateBarHeight(value: meal.proteins), barColor: .blue)
            MacroBarView(value: meal.fats, name: "Fats", height: calculateBarHeight(value: meal.fats), barColor: .green)
        }
    }
    
    private func calculateTotalGrams() -> CGFloat {
        CGFloat(meal.carbs + meal.proteins + meal.fats)
    }
    
    private func calculateBarHeight(value: Int) -> CGFloat {
        barsMaxHeight * CGFloat(value) / calculateTotalGrams()
    }
}

#Preview {
    MacroBarsView(meal: Meal.mockMeal)
}
