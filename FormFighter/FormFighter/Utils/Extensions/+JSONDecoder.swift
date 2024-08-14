import Foundation

extension JSONDecoder {
    func emptyDecode<T: Decodable>(_ type: T.Type, from data: Data, status: Int) throws -> T {
        if (data.isEmpty) {
            if let emptyResponse = EmptyResponse(status: status) as? T {
                return emptyResponse
            } else {
                Logger.log(message: "Cannot cast \(type.self) empty response", event: .error)
                throw RequestError.decode
            }
        } else {
            Logger.log(message: "Data is not empty. Error decoding empty response.", event: .error)
            throw RequestError.decode
        }
    }
}
