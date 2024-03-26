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

protocol AnalyzeMealProtocol {
    func analyzeMeal(with model: MealVisionRequestModel) async throws -> MealVisionResponse
}

// This is a example of how you can request to Vision API image analysis to our backend.
// You can tweak the request models depending on your needs and handle them in the backend to
// build proper prompts.
class AnalyzeMealVisionService: AnalyzeMealProtocol {
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

// This is an example of how you can use AI Proxy to make requests to OpenAI Vision instead of using the Node AI Backend
class AnalyzeMealAIProxyService: AnalyzeMealProtocol {
    
    func analyzeMeal(with model: MealVisionRequestModel) async throws -> MealVisionResponse {
        
        guard let localURL = model.image.toAIProxyURL else {
            throw AnalyzeMealVisionError.analyzeMealError
        }
        
        let content: [AIProxy.Message.ContentType.MessageContent] = [
            .imageUrl(localURL)
        ]
        
        let prompt = "Based on the photo of a meal provided, analyze it as if you were a nutritionist and calculate the total calories, calories per 100 grams, carbs, proteins and fats. Name the meal in \(model.language). Please, always return only a JSON object with the following properties: 'name', 'total_calories_estimation': INT, 'calories_100_grams': INT, 'carbs': INT, 'proteins': INT, 'fats': INT."
        
        // You can tweak from here parameters like the model to use, max tokens, how the system should be have etc...
        // It's the same as we would do in the Node backend.
        let requestBody = AIProxy.ChatRequestBody(
            model: "gpt-4-vision-preview",
            messages: [
                .init(role: "user", content: .contentArray(content)),
                .init(role: "system", content: .text(prompt))
            ],
            maxTokens: 1000
        )
        
        let response = try await AIProxy.chatCompletionRequest(
            chatRequestBody: requestBody
        )
        
        // As we do in in the Node backend, we get the message from the first choice and remove the markdown syntax that wraps the JSON text.
        guard let responseText = response.choices.first?.message.content.removeMarkdownJsonSyntax else {
            throw AnalyzeMealVisionError.analyzeMealError
        }
        
        let jsonData = Data(responseText.utf8)
        
        // We try to encode the JSON meal analysis response into our Model.
        // If it fails we throw and error. If not, we return our model to consume from the VM and View.
        do {
            let mealVisionResponse = try JSONDecoder().decode(MealVisionResponse.self, from: jsonData)
            return mealVisionResponse
        } catch {
            throw AnalyzeMealVisionError.analyzeMealError
        }
    }
    
}

