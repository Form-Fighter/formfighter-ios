import SwiftUI

// The model we use within the app to represent a meal
struct Meal {
    let id = UUID().uuidString
    let date = Date()
    let name: String
    let image: Image
    let totalCaloriesEstimation, calories100Grams, carbs, proteins, fats: Int
    
    init(name: String, image: Image, totalCaloriesEstimation: Int, calories100Grams: Int, carbs: Int, proteins: Int, fats: Int) {
        self.name = name
        self.image = image
        self.totalCaloriesEstimation = totalCaloriesEstimation
        self.calories100Grams = calories100Grams
        self.carbs = carbs
        self.proteins = proteins
        self.fats = fats
    }
    
    init(with response: MealVisionResponse, image: Image) {
        self.name = response.name
        self.image = image
        self.totalCaloriesEstimation = response.totalCaloriesEstimation
        self.calories100Grams = response.calories100Grams
        self.carbs = response.carbs
        self.proteins = response.proteins
        self.fats = response.fats
    }
    
}

extension Meal {
    static let mockMeal: Meal = .init(with: MealVisionResponse.mockMealResponse,
                                      image: Image(systemName: "fork.knife.circle.fill"))
}
