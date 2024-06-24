//  Created by Steven Curtis

import Foundation

public enum APIError: Equatable, Error, LocalizedError {
    case network(errorMessage: String)
    case noData
    case parseResponse(errorMessage: String)
    case request
    case httpError(HTTPError)
    case invalidResponse(Data?, URLResponse?)
    case bearerToken
    case unknown
    public var errorDescription: String? {
        switch self {
        case .request:
            return "Could not process request"
        case .network(errorMessage: let error):
            return error
        case .noData:
            return "No data"
        case .parseResponse(let error):
            return error
        case .httpError(let error):
            return error.localizedDescription
        case .invalidResponse:
            return "Invalid response"
        case .bearerToken:
            return "Bearer token error"
        case .unknown:
            return "Unknown Error"
        }
    }
}
