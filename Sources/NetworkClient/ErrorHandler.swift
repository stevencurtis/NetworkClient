//  Created by Steven Curtis

import Foundation

public protocol ErrorHandlerProtocol {
    func handleStatusCode(statusCode: Int) throws
    func handleResponse(_ data: Data, _ response: URLResponse?) throws -> HTTPURLResponse
}

public struct ErrorHandler: ErrorHandlerProtocol {
    public func handleStatusCode(statusCode: Int) throws {
        switch statusCode {
        case 200..<300:
            break
        case 400:
            throw APIError.httpError(.badRequest)
        case 401:
            throw APIError.httpError(.unauthorized)
        case 403:
            throw APIError.httpError(.forbidden)
        case 404:
            throw APIError.httpError(.notFound)
        case 500:
            throw APIError.httpError(.serverError)
        default:
            throw APIError.httpError(.unknown)
        }
    }
    
    public func handleResponse(_ data: Data, _ response: URLResponse?) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(data, response)
        }
        return httpResponse
    }
    
    public static func make() -> ErrorHandlerProtocol {
        ErrorHandler()
    }
}
