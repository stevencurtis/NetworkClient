//  Created by Steven Curtis

import Foundation

public enum ApiResponse<T> {
    case success(T)
    case failure(ApiError)

    public var result: Result<T, ApiError> {
        switch self {
        case let .success(value):
            return .success(value)
        case let .failure(error):
            return .failure(error)
        }
    }
}
