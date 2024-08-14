import Foundation

protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get async}
    var body: [String: String]? { get }
}

extension Endpoint {
    var baseURL: String {
        return Const.Api.baseURL
    }
}
