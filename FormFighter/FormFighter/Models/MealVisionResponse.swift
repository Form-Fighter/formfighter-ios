import Foundation

// The model that our backend send back to the app when we request an image analysis
struct MealVisionResponse: Codable {
    let name: String
    let totalCaloriesEstimation, calories100Grams, carbs, proteins, fats: Int
    
    enum CodingKeys: String, CodingKey {
        case name, carbs, proteins, fats
        case totalCaloriesEstimation = "total_calories_estimation"
        case calories100Grams = "calories_100_grams"
    }
}

extension MealVisionResponse {
    static let mockMealResponse: MealVisionResponse = .init(name: "Meal", totalCaloriesEstimation: 442, calories100Grams: 133, carbs: 30, proteins: 12, fats: 7)
}
