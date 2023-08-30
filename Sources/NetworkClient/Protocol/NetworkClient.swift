//  Created by Steven Curtis

import Foundation

public protocol NetworkClient {
    @discardableResult
    func request<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T,
        completionHandler: @escaping (ApiResponse<T.ResponseDataType>) -> Void
    ) -> URLSessionTask?
    
    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T
    ) async throws -> T.ResponseDataType
}
