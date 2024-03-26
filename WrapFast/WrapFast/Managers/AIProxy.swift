import Foundation
import OSLog
import DeviceCheck
import UIKit

// MARK: - This is part of AI Proxy Documentation: https://www.aiproxy.pro/docs/

/* ------------------------- Begin placeholder --------------------------------- */
///
/// Instructions for integration:
/// 1. Drop this file into your Xcode project
/// 2. Replace this section with the constants that you received at dashboard.aiproxy.pro
/// 3. Read the integration examples directly following this placeholder
///
private let aiproxyPartialKey = "aiproxyPartialKey"
#if DEBUG && targetEnvironment(simulator)
private let aiproxyDeviceCheckBypass = "aiproxyDeviceCheckBypass"
#endif
/* -------------------------- End placeholder ---------------------------------- */

/// This file provides four different options to integrate with aiproxy.pro:
///
///     1. non-streaming chat using async/await
///     2. non-streaming chat using callbacks
///     3. streaming chat using async/await
///     4. streaming chat using callbacks
///
/// If you choose to use the callback-based interface, callbacks are guaranteed to be invoked on the main thread.
/// All internal work is done using the modern async/await APIs for URLSession.
///
/// # Example integration of non-streaming chat using async/await
///
/// ```
///     let requestBody = AIProxy.ChatRequestBody(
///         model: "gpt-4-0125-preview",
///         messages: [
///             AIProxy.Message(role: "user", content: "hello world")
///         ]
///     )
///
///     let task = Task {
///         do {
///             let response = try await AIProxy.chatCompletionRequest(
///                 chatRequestBody: requestBody
///             )
///             // Do something with `response`. For example:
///             print(response.choices.first?.message.content ?? "")
///         } catch {
///             // Handle error. For example:
///             print(error.localizedDescription)
///         }
///     }
///
///     // Uncomment this to cancel the request:
///     // task.cancel()
/// ```
///
///
/// # Example integration of non-streaming chat using callbacks
///
/// ```
///     let requestBody = AIProxy.ChatRequestBody(
///         model: "gpt-4-0125-preview",
///         messages: [
///             AIProxy.Message(role: "user", content: "hello world")
///         ]
///     )
///
///     let task = AIProxy.chatCompletionRequest(chatRequestBody: requestBody) { result in
///         switch result {
///         case .success(let response):
///             // Do something with `response`. For example:
///             print(response.choices.first?.message.content ?? "")
///         case .failure(let error):
///             // Handle error. For example:
///             print(error.localizedDescription)
///         }
///     }
///
///     // Uncomment this to cancel the request:
///     // task.cancel()
/// ```
///
///
/// # Example integration of streaming chat using async/await
///
/// ```
///     let requestBody = AIProxy.ChatRequestBody(
///         model: "gpt-4-0125-preview",
///         messages: [
///             AIProxy.Message(role: "user", content: "hello world")
///         ],
///         stream: true
///     )
///
///     let task = Task {
///         do {
///             let stream = try await AIProxy.streamingChatCompletionRequest(chatRequestBody: requestBody)
///             for try await chunk in stream {
///                 // Do something with `chunk`. For example:
///                 print(chunk.choices.first?.delta.content ?? "")
///             }
///         } catch {
///             // Handle error. For example:
///             print(error.localizedDescription)
///         }
///     }
///
///     // Uncomment this to cancel the request or stop the streaming response:
///     // task.cancel()
/// ```
///
///
/// ### Example integration of streaming chat using callbacks
///
/// ```
///     // Craft your request body per the 'Request body' documentation here:
///     // https://platform.openai.com/docs/api-reference/chat/create
///     let requestBody = AIProxy.ChatRequestBody(
///         model: "gpt-4-0125-preview",
///         messages: [
///             AIProxy.Message(role: "user", content: "hello world")
///         ],
///         stream: true
///     )
///
///     let task = AIProxy.streamingChatCompletionRequest(chatRequestBody: requestBody) { chunk in
///         // Do something with `chunk`. For example:
///         print(chunk.choices.first?.delta.content ?? "")
///     } completion: { error in
///         if let error = error {
///             // Handle error. For example:
///             print(error.localizedDescription)
///         }
///     }
///
///     // Uncomment this to cancel the request or stop the streaming response:
///     // task.cancel()
/// ```

private let aiproxyURL = "https://api.aiproxy.pro"
private let aiproxyChatPath = "/v1/chat/completions"
private let aiproxyImageGenerationPath = "/v1/images/generations"

// MARK: - Public API
protocol AIProxyCancelable {
    /// Cancels the AIProxy operation
    func cancel()
}

/// Conform Task to AIProxyCancelable to make the public signatures in the `AIProxy` struct a bit more readable
extension Task<(), Never>: AIProxyCancelable {}

/// Errors
enum AIProxyError: Error {
    /// The aiproxy endpoint defined in the customer's integration code could not be used to construct a URLRequest
    case badEndpoint
    
    /// The aiproxy path defined in the customer's integration code could not be used to construct a URLRequest
    case badPath
}

struct AIProxy {
    private init() { fatalError("AIProxy is a namespace only") }
    
    /// Initiates an async/await-based, non-streaming chat completion request to /v1/chat/completions.
    /// See the usage instructions at the top of this file.
    ///
    /// - Parameters:
    ///   - chatRequestBody: The request body to send to aiproxy and openai. See this reference:
    ///                      https://platform.openai.com/docs/api-reference/chat/create
    /// - Returns: A ChatCompletionResponse. See this reference:
    ///            https://platform.openai.com/docs/api-reference/chat/object
    static func chatCompletionRequest(
        chatRequestBody: AIProxy.ChatRequestBody
    ) async throws -> AIProxy.ChatCompletionResponse {
        let session = URLSession(configuration: .default)
        session.sessionDescription = "AIProxy Buffered" // See "Analyze HTTP traffic in Instruments" wwdc session
        let request = try await buildAIProxyRequest(requestBody: chatRequestBody, path: aiproxyChatPath)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AIProxy.ChatCompletionResponse.self, from: data)
    }
    
    /// Initiates an async/await-based, streaming chat completion request to /v1/chat/completions.
    /// See the usage instructions at the top of this file.
    ///
    /// - Parameters:
    ///   - chatRequestBody: The request body to send to aiproxy and openai. See this reference:
    ///                      https://platform.openai.com/docs/api-reference/chat/create
    /// - Returns: An iterable sequence of ChatCompletionChunk objects. See this reference:
    ///            https://platform.openai.com/docs/api-reference/chat/streaming
    static func streamingChatCompletionRequest(
        chatRequestBody: AIProxy.ChatRequestBody
    ) async throws -> AsyncCompactMapSequence<AsyncLineSequence<URLSession.AsyncBytes>, AIProxy.ChatCompletionChunk> {
        let session = URLSession(configuration: .default)
        session.sessionDescription = "AIProxy Streaming" // See "Analyze HTTP traffic in Instruments" wwdc session
        let request = try await buildAIProxyRequest(requestBody: chatRequestBody, path: aiproxyChatPath)
        let (asyncBytes, _) = try await session.bytes(for: request)
        return asyncBytes.lines.compactMap { AIProxy.ChatCompletionChunk.from(line: $0) }
    }
    
    /// Initiates a callback-based, non-streaming chat completion request to /v1/chat/completions.
    /// See the usage instructions at the top of this file.
    ///
    /// - Parameters:
    ///   - chatRequestBody: The request body to send to aiproxy and openai. See this reference:
    ///                      https://platform.openai.com/docs/api-reference/chat/create
    ///   - completion: A callback that is invoked when the chat completion response is received.
    ///                 The callback's argument is a ChatCompletionResponse. See this reference:
    ///                 https://platform.openai.com/docs/api-reference/chat/object
    /// - Returns: A task that the caller can use to cancel the request, if desired
    static func chatCompletionRequest(
        chatRequestBody: AIProxy.ChatRequestBody,
        completion: @escaping (Result<AIProxy.ChatCompletionResponse, Error>) -> Void
    ) -> AIProxyCancelable? {
        assert(!chatRequestBody.stream, "Please use `streamingChatCompletionRequest` for streaming requests")
        
        // Bridge to the modern API
        return Task {
            do {
                let response = try await AIProxy.chatCompletionRequest(
                    chatRequestBody: chatRequestBody
                )
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Initiates an async/await-based, image generation request to /v1/image/generations
    /// See the usage instructions at the top of this file.
    ///
    /// - Parameters:
    ///   - imageRequestBody: The request body to send to aiproxy and openai. See this reference:
    ///                      https://platform.openai.com/docs/api-reference/images/create
    /// - Returns: An ImageGenerationResponse. See this reference:
    ///            https://platform.openai.com/docs/api-reference/images/object
    static func imageGenerationRequest(
        imageRequestBody: AIProxy.ImageGenerationRequestBody
    ) async throws -> AIProxy.ImageGenerationResponseObject {
        let session = URLSession(configuration: .default)
        session.sessionDescription = "AIProxy Buffered" // See "Analyze HTTP traffic in Instruments" wwdc session
        let request = try await buildAIProxyRequest(requestBody: imageRequestBody, path: aiproxyImageGenerationPath)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AIProxy.ImageGenerationResponseObject.self, from: data)
    }
    
    /// Initiates a callback-based, streaming chat completion request to /v1/chat/completions.
    /// See the usage instructions at the top of this file.
    ///
    /// - Parameters:
    ///   - chatRequestBody: The request body to send to aiproxy and openai. See this reference:
    ///                      https://platform.openai.com/docs/api-reference/chat/create
    ///   - partialResponse: A callback that is invoked each time a chunk of the response is received.
    ///                      The callback's argument is a ChatCompletionChunk. See this reference:
    ///                      https://platform.openai.com/docs/api-reference/chat/streaming
    ///   - completion: A callback that is invoked when the response is finished.
    ///
    /// - Returns: A task that the caller can use to cancel the request/response, if desired
    static func streamingChatCompletionRequest(
        chatRequestBody: AIProxy.ChatRequestBody,
        partialResponse: @escaping (AIProxy.ChatCompletionChunk) -> Void,
        completion: @escaping (Error?) -> Void
    ) -> AIProxyCancelable? {
        assert(chatRequestBody.stream, "Please use `chatCompletionRequest` for non-streaming requests")
        
        // Bridge to the modern API
        return Task {
            do {
                let stream = try await AIProxy.streamingChatCompletionRequest(
                    chatRequestBody: chatRequestBody
                )
                
                for try await chunk in stream {
                    DispatchQueue.main.async {
                        partialResponse(chunk)
                    }
                }
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    /// Codable representation of a chat request body. Add to this if you need additional parameters specified here:
    /// https://platform.openai.com/docs/api-reference/chat/create
    struct ChatRequestBody: Encodable {
        let model: String
        let messages: [Message]
        let maxTokens: Int?
        var stream: Bool = false
        
        func serialize() throws -> Data {
            return try JSONEncoder().encode(self)
        }
        
        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case maxTokens = "max_tokens"
            case stream
        }
    }
    
    /// Codable representation of a chat response object. Add to this if you need additional fields specified here:
    /// https://platform.openai.com/docs/api-reference/chat/object
    struct ChatCompletionResponse: Decodable {
        let choices: [Choice]
    }
    
    struct Choice: Decodable {
        let message: MessageRes
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    
    public enum Role: String {
        case system
        case user
        case assistant
        case tool
    }
    
    struct MessageRes: Decodable {
        let role: String
        let content: String
    }
    
    
    struct Message: Encodable {
        let role: String
        /// The contents of the message. content is required for all messages, and may be null for assistant messages with function calls.
        let content: ContentType
        
        public enum ContentType: Encodable {
            
            case text(String)
            case contentArray([MessageContent])
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .text(let text):
                    try container.encode(text)
                case .contentArray(let contentArray):
                    try container.encode(contentArray)
                }
            }
            
            public enum MessageContent: Encodable, Equatable, Hashable {
                
                case text(String)
                case imageUrl(URL)
                
                enum CodingKeys: String, CodingKey {
                    case type
                    case text
                    case imageUrl = "image_url"
                }
                
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    switch self {
                    case .text(let text):
                        try container.encode("text", forKey: .type)
                        try container.encode(text, forKey: .text)
                    case .imageUrl(let url):
                        try container.encode("image_url", forKey: .type)
                        try container.encode(url, forKey: .imageUrl)
                    }
                }
                
                public func hash(into hasher: inout Hasher) {
                    switch self {
                    case .text(let string):
                        hasher.combine(string)
                    case .imageUrl(let url):
                        hasher.combine(url)
                    }
                }
                
                public static func ==(lhs: MessageContent, rhs: MessageContent) -> Bool {
                    switch (lhs, rhs) {
                    case let (.text(a), .text(b)):
                        return a == b
                    case let (.imageUrl(a), .imageUrl(b)):
                        return a == b
                    default:
                        return false
                    }
                }
            }
        }
    }
    
    /// Codable representation of a chat streaming response chunk. Add to this if you need additional fields specified here:
    /// https://platform.openai.com/docs/api-reference/chat/streaming
    struct ChatCompletionChunk: Codable {
        let choices: [ChunkChoice]
    }
    
    struct ChunkChoice: Codable {
        let delta: Delta
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case delta
            case finishReason = "finish_reason"
        }
    }
    
    struct Delta: Codable {
        let role: String?
        let content: String?
    }
    
    struct ImageGenerationResponse: Decodable {
        /// The URL of the generated image, if response_format is url (default).
        let url: URL?
        /// The base64-encoded JSON of the generated image, if response_format is b64_json.
        let b64Json: String?
        /// The prompt that was used to generate the image, if there was any revision to the prompt.
        let revisedPrompt: String?
        enum CodingKeys: String, CodingKey {
            case url
            case b64Json = "b64_json"
            case revisedPrompt = "revised_prompt"
        }
    }
    
    struct ImageGenerationResponseObject: Decodable {
        let data: [ImageGenerationResponse]
    }
    
    /// [Creates an image given a prompt.](https://platform.openai.com/docs/api-reference/images/create)
    struct ImageGenerationRequestBody: Encodable {
        /// A text description of the desired image(s). The maximum length is 1000 characters for dall-e-2 and 4000 characters for dall-e-3.
        let prompt: String
        /// The size of the generated images. Must be one of 256x256, 512x512, or 1024x1024 for dall-e-2. Must be one of 1024x1024, 1792x1024, or 1024x1792 for dall-e-3 models. Defaults to 1024x1024
        let size: String
        /// The model to use for image generation. Defaults to dall-e-2
        let model: String?
        /// The number of images to generate. Must be between 1 and 10. For dall-e-3, only n=1 is supported.
        let n: Int?
        /// The quality of the image that will be generated. hd creates images with finer details and greater consistency across the image. This param is only supported for dall-e-3. Defaults to standard
        let quality: String?
        /// The format in which the generated images are returned. Must be one of url or b64_json. Defaults to url
        let responseFormat: String?
        /// The style of the generated images. Must be one of vivid or natural. Vivid causes the model to lean towards generating hyper-real and dramatic images. Natural causes the model to produce more natural, less hyper-real looking images. This param is only supported for dall-e-3. Defaults to vivid
        let style: String?
        /// A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](https://platform.openai.com/docs/guides/safety-best-practices)
        let user: String?
        enum ImageResponseFormat: String {
            case url = "url"
            case b64Json = "b64_json"
        }
        enum CodingKeys: String, CodingKey {
            case prompt
            case model
            case n
            case quality
            case responseFormat = "response_format"
            case size
            case style
            case user
        }
        init(
            prompt: String,
            size: String,
            numberOfImages: Int = 1,
            quality: String? = nil,
            responseFormat: ImageResponseFormat? = nil,
            style: String? = nil,
            user: String? = nil)
        {
            self.prompt = prompt
            self.size = size
            self.model = "dall-e-3"
            self.n = numberOfImages
            self.quality = quality
            self.responseFormat = responseFormat?.rawValue
            self.style = style
            self.user = user
        }
    }
}



struct ImageGenerationResponse: Decodable {
    /// The URL of the generated image, if response_format is url (default).
    let url: URL?
    /// The base64-encoded JSON of the generated image, if response_format is b64_json.
    let b64Json: String?
    /// The prompt that was used to generate the image, if there was any revision to the prompt.
    let revisedPrompt: String?
    enum CodingKeys: String, CodingKey {
        case url
        case b64Json = "b64_json"
        case revisedPrompt = "revised_prompt"
    }
}

struct ImageGenerationResponseObject: Decodable {
    let data: [ImageGenerationResponse]
}

/// [Creates an image given a prompt.](https://platform.openai.com/docs/api-reference/images/create)
struct ImageGenerationRequestBody: Encodable {
    /// A text description of the desired image(s). The maximum length is 1000 characters for dall-e-2 and 4000 characters for dall-e-3.
    let prompt: String
    /// The size of the generated images. Must be one of 256x256, 512x512, or 1024x1024 for dall-e-2. Must be one of 1024x1024, 1792x1024, or 1024x1792 for dall-e-3 models. Defaults to 1024x1024
    let size: String
    /// The model to use for image generation. Defaults to dall-e-2
    let model: String?
    /// The number of images to generate. Must be between 1 and 10. For dall-e-3, only n=1 is supported.
    let n: Int?
    /// The quality of the image that will be generated. hd creates images with finer details and greater consistency across the image. This param is only supported for dall-e-3. Defaults to standard
    let quality: String?
    /// The format in which the generated images are returned. Must be one of url or b64_json. Defaults to url
    let responseFormat: String?
    /// The style of the generated images. Must be one of vivid or natural. Vivid causes the model to lean towards generating hyper-real and dramatic images. Natural causes the model to produce more natural, less hyper-real looking images. This param is only supported for dall-e-3. Defaults to vivid
    let style: String?
    /// A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](https://platform.openai.com/docs/guides/safety-best-practices)
    let user: String?
    enum ImageResponseFormat: String {
        case url = "url"
        case b64Json = "b64_json"
    }
    enum CodingKeys: String, CodingKey {
        case prompt
        case model
        case n
        case quality
        case responseFormat = "response_format"
        case size
        case style
        case user
    }
    init(
        prompt: String,
        size: String,
        numberOfImages: Int = 1,
        quality: String? = nil,
        responseFormat: ImageResponseFormat? = nil,
        style: String? = nil,
        user: String? = nil)
    {
        self.prompt = prompt
        self.size = size
        self.model = "dall-e-3"
        self.n = numberOfImages
        self.quality = quality
        self.responseFormat = responseFormat?.rawValue
        self.style = style
        self.user = user
    }
}

// MARK: - Private Helpers

/// Gets a device check token for use in your calls to aiproxy.
/// The device token may be nil when targeting the iOS simulator.
/// See the usage instructions at the top of this file, and ensure that you are conditionally compiling the `deviceCheckBypass` token for iOS simulation only.
/// Do not let the `deviceCheckBypass` token slip into your production codebase, or an attacker can easily use it themselves.
private func getDeviceCheckToken() async -> String? {
    guard DCDevice.current.isSupported else {
        Logger.log(message: "DeviceCheck is not available on this device. Are you on the simulator?", event: .error)
        return nil
    }
    
    do {
        let data = try await DCDevice.current.generateToken()
        return data.base64EncodedString()
    } catch {
        Logger.log(message: "Could not create DeviceCheck token. Are you using an explicit bundle identifier?", event: .error)
        return nil
    }
}

/// Get a unique ID for this user (scoped to the current vendor, and not personally identifiable):
private func getVendorID() -> String? {
    return UIDevice.current.identifierForVendor?.uuidString
}

/// Builds and AI Proxy request.
/// Used for both streaming and non-streaming chat.
private func buildAIProxyRequest(requestBody: Encodable, path: String) async throws -> URLRequest {
    let postBody = try JSONEncoder().encode(requestBody)
    let deviceCheckToken = await getDeviceCheckToken()
    let vendorID = getVendorID()
    guard var urlComponents = URLComponents(string: aiproxyURL) else {
        Logger.log(message: "Could not create urlComponents, please check the aiproxyEndpoint constant", event: .error)
        throw AIProxyError.badEndpoint
    }
    urlComponents.path = path
    
    guard let url = urlComponents.url else {
        Logger.log(message: "Could not create a request URL", event: .error)
        throw AIProxyError.badPath
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = postBody
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(aiproxyPartialKey, forHTTPHeaderField: "aiproxy-partial-key")
    if let vendorID = vendorID {
        request.addValue(vendorID, forHTTPHeaderField: "aiproxy-vendor-id")
    }
    if let deviceCheckToken = deviceCheckToken {
        request.addValue(deviceCheckToken, forHTTPHeaderField: "aiproxy-devicecheck")
    }
#if DEBUG && targetEnvironment(simulator)
    request.addValue(aiproxyDeviceCheckBypass, forHTTPHeaderField: "aiproxy-devicecheck-bypass")
#endif
    return request
}


private extension AIProxy.ChatCompletionChunk {
    /// Creates a ChatCompletionChunk from a streamed line of the /v1/chat/completions response
    static func from(line: String) -> Self? {
        guard line.hasPrefix("data: ") else {
            Logger.log(message: "Received unexpected line from aiproxy: \(line)", event: .error)
            return nil
        }
        
        guard line != "data: [DONE]" else {
            Logger.log(message: "Streaming response has finished", event: .error)
            return nil
        }
        
        guard let chunkJSON = line.dropFirst(6).data(using: .utf8),
              let chunk = try? JSONDecoder().decode(AIProxy.ChatCompletionChunk.self, from: chunkJSON) else
        {
            Logger.log(message: "Received unexpected JSON from aiproxy: \(line)", event: .warning)
            return nil
        }
        Logger.log(message: "Received a chunk: \(line)", event: .debug)
        return chunk
    }
}
