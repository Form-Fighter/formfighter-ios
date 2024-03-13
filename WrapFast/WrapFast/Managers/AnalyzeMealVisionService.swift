import Foundation

enum AnalyzeMealVisionError: Error {
    case analyzeMealError
    
    var localizedDescription: String {
        switch self {
        case .analyzeMealError:
            "Error analyzing meal"
        }
    }
}

// This is a example of how you can request to Vision API image analysis.
// You can tweak the request models depending on your needs and handle them in the backend to
// build proper prompts.
class AnalyzeMealVisionService {
    func analyzeMeal(with model: MealVisionRequestModel) async throws -> MealVisionResponse {
        let result = try await ApiClient.shared.sendRequest(
            endpoint: Endpoints.vision,
            body: JSONEncoder().encode(model),
            responseModel: MealVisionResponse.self
        )
        
        switch result {
        case .success(let mealResponse):
            return mealResponse
        case .failure(let failure):
            Logger.log(message: failure.localizedDescription, event: .error)
            throw AnalyzeMealVisionError.analyzeMealError
        }
    }
}
