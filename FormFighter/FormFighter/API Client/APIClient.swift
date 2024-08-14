import Foundation

struct ApiError: Error, Decodable {
    let	title: String
    let description: String
    let code: Int
}

protocol APIClientProtocol {
    func sendRequest<T: Decodable>(
        endpoint: Endpoint,
        queryParams: [URLQueryItem]?,
        body: Data?,
        pathExtension: String?,
        responseModel: T.Type,
        allowRetry: Bool
    ) async -> Result<T, RequestError>
}

extension APIClientProtocol {
    func sendRequest<T: Decodable>(
        endpoint: Endpoint,
        queryParams: [URLQueryItem]? = nil,
        body: Data? = nil,
        pathExtension: String? = nil,
        responseModel: T.Type,
        allowRetry: Bool = true
    ) async -> Result<T, RequestError> {
        await sendRequest(endpoint: endpoint, queryParams: queryParams, body: body, pathExtension: pathExtension, responseModel: responseModel, allowRetry: allowRetry)
    }
}


struct ApiClient: APIClientProtocol {
    static let shared: APIClientProtocol = ApiClient()
    private init() {}
    
    func sendRequest<T: Decodable>(
        endpoint: Endpoint,
        queryParams: [URLQueryItem]? = nil,
        body: Data? = nil,
        pathExtension: String? = nil,
        responseModel: T.Type,
        allowRetry: Bool = true) async -> Result<T, RequestError> {
            
            var urlPath = endpoint.baseURL + endpoint.path
            
            if let pathExtension {
                urlPath.append("/\(pathExtension)")
            }
            
            let urlComponents = NSURLComponents(string: urlPath)
            urlComponents?.queryItems = queryParams
            
            guard let url = urlComponents?.url else {
                Logger.log(message: RequestError.invalidURL.errorMessage, event: .error)
                return .failure(.invalidURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = endpoint.method.rawValue
            
            if let headers = await endpoint.header {
                request.allHTTPHeaderFields = headers
            }
            
            switch endpoint.method {
            case .post, .put:
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            default:
                break
            }
            
            let sessionConfiguration = URLSessionConfiguration.default
            sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
            
            let session = URLSession(configuration: sessionConfiguration)
            
            request.httpBody = body
            request.timeoutInterval = Const.Api.requestTimeout
            
            do {
                session.dataTask(with: request) { data, response, error in
                    print("finished")
                }
                let (data, response) = try await session.data(for: request)
                guard let response = response as? HTTPURLResponse else {
                    Logger.log(message: RequestError.noResponse.errorMessage, event: .error)
                    return .failure(.noResponse)
                }
                
                switch response.statusCode {
                case 200...299:
                    Logger.log(message: "Server response code: \(response.statusCode)", event: .debug)
                    
                    do {
                        if data.isEmpty {
                            let decodedResponse = try JSONDecoder().emptyDecode(T.self, from: data, status: response.statusCode)
                            Logger.log(message: "Empty Response decoded successfully", event: .debug)
                            return .success(decodedResponse)
                        }
                        
                        let decodedResponse = try JSONDecoder().decode(responseModel, from: data)
                        Logger.log(message: "Response decoded successfully", event: .debug)
                        return .success(decodedResponse)
                    }
                    catch DecodingError.keyNotFound(let key, let context) {
                        Logger.log(message: "Failed to decode \(responseModel.self) due to missing key '\(key.stringValue)' not found – \(context.debugDescription)", event: .error)
                        return .failure(.decode)
                    } catch DecodingError.typeMismatch(_, let context) {
                        Logger.log(message: "Failed to decode \(responseModel.self) due to type mismatch – \(context.debugDescription)", event: .error)
                        return .failure(.decode)
                    } catch DecodingError.valueNotFound(let type, let context) {
                        Logger.log(message: "Failed to decode \(responseModel.self) due to missing \(type) value – \(context.debugDescription)", event: .error)
                        return .failure(.decode)
                    } catch DecodingError.dataCorrupted(_) {
                        Logger.log(message: "Failed to decode \(responseModel.self) because it appears to be invalid JSON", event: .error)
                        
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print(jsonString)
                        }
                        
                        return .failure(.decode)
                    } catch {
                        Logger.log(message: "Failed to decode \(responseModel.self): \(error.localizedDescription)", event: .error)
                        return .failure(.decode)
                    }
                case 401:
                    if allowRetry {
                        Logger.log(message: "Authentication failed. Retrying request in \(Const.Api.retryDelay)s . . .", event: .error)
                        sleep(Const.Api.retryDelay)
                        return await sendRequest(endpoint: endpoint, queryParams: queryParams, body: body, pathExtension: pathExtension, responseModel: responseModel, allowRetry: false)
                    }
                    Logger.log(message: "Authentication error, code: \(response.statusCode)", event: .error)
                    let decodedError = try JSONDecoder().decode(ApiError.self, from: data)
                    Logger.log(message: "Error title: \(decodedError.title). Error description: \(decodedError.description). Error code: \(decodedError.code). Error localizedDescription: \(decodedError.localizedDescription)", event: .error)
                    return .failure(.unAuthorized(code: decodedError.code))
                default:
                    if let decodedError = try? JSONDecoder().decode(ApiError.self, from: data) {
                        Logger.log(message: "Error title: \(decodedError.title). Error description: \(decodedError.description). Error code: \(decodedError.code). Error localizedDescription: \(decodedError.localizedDescription)", event: .error)
                        return .failure(.serverError(code: decodedError.code))
                    } else {
                        Logger.log(message: "Status Code \(response.statusCode)" , event: .error)
                        return .failure(.serverError(code: response.statusCode))
                    }
                }
                
            } catch {
                Logger.log(message: "Unknown error: \(error.localizedDescription)", event: .error)
                return .failure(.unknown)
            }
        }
}
