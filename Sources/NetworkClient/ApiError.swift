//  Created by Steven Curtis

import Foundation

public enum ApiError: Equatable, Error {
    var localizedDescription: String {
        switch self {
        case .generic:
            return "error"
        case .network(errorMessage: let error):
            return error
        case .noData:
            return "No data"
        case .parseResponse:
            return "Could not parse response"
        }
    }
    case generic
    case network(errorMessage: String)
    case noData
    case parseResponse
}
