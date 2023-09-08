//  Created by Steven Curtis

import Foundation

public enum ApiError: Equatable, Error {
    var localizedDescription: String {
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
        case .unknown:
            return "Unknown Error"
        }
    }
    case network(errorMessage: String)
    case noData
    case parseResponse(errorMessage: String)
    case request
    case httpError(HTTPError)
    case invalidResponse(Data?, URLResponse?)
    case unknown
}

public enum HTTPError: Error {
    case badRequest // 400
    case unauthorized // 401
    case forbidden // 403
    case notFound // 404
    case serverError // 500
    case unknown // for other status codes

    var localizedDescription: String {
        switch self {
        case .badRequest:
            return "Bad Request"
        case .unauthorized:
            return "Unauthorized"
        case .forbidden:
            return "Forbidden"
        case .notFound:
            return "Not Found"
        case .serverError:
            return "Internal Server Error"
        case .unknown:
            return "Unknown HTTP Error"
        }
    }
}
