import Foundation

// The model we send to our backend in order to make a request to Vision API
// In this example, we ask to analyze the picture of a meal.
// We send the language we want it to respond in as a parameter.
struct MealVisionRequestModel: Encodable {
    let image: String
    let language: String
}
