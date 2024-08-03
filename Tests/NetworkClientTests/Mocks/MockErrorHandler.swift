//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

struct MockErrorHandler: ErrorHandlerProtocol {
    var shouldThrowError: Bool
    var errorToThrow: APIError?
    
    func handleStatusCode(statusCode: Int) throws {
        if shouldThrowError {
            if let error = errorToThrow {
                throw error
            } else {
                throw APIError.httpError(.unknown)
            }
        }
    }
    
    func handleResponse(_ data: Data, _ response: URLResponse?) throws -> HTTPURLResponse {
        if shouldThrowError {
            throw APIError.invalidResponse(data, response)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(data, response)
        }
        return httpResponse
    }
}
