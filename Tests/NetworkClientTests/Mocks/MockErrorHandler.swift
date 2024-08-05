//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

final class MockErrorHandler: ErrorHandlerProtocol {
    var shouldThrowError: Bool = false
    var errorToThrow: APIError? = nil
    private(set) var handleResponseCallCount: Int = 0
    private(set) var handleStatusCodeCallCount: Int = 0
    
    init(shouldThrowError: Bool) {
        self.shouldThrowError = shouldThrowError
    }
    
    func handleStatusCode(statusCode: Int) throws {
        handleStatusCodeCallCount += 1
        if shouldThrowError {
            if let error = errorToThrow {
                throw error
            } else {
                throw APIError.httpError(.unknown)
            }
        }
    }
    
    func handleResponse(_ data: Data, _ response: URLResponse?) throws -> HTTPURLResponse {
        handleResponseCallCount += 1
        if shouldThrowError {
            throw APIError.invalidResponse(data, response)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(data, response)
        }
        return httpResponse
    }
}
