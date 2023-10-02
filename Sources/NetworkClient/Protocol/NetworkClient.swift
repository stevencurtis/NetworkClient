//  Created by Steven Curtis

import Foundation

public protocol NetworkClient {
    @discardableResult
    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T,
        completionQueue: DispatchQueue,
        completionHandler: @escaping (ApiResponse<T.ResponseDataType?>) -> Void
    ) -> URLSessionTask?

    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T
    ) async throws -> T.ResponseDataType?
}

public extension NetworkClient {
    @discardableResult
    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T = DefaultRequest(),
        completionHandler: @escaping (ApiResponse<T.ResponseDataType?>) -> Void
    ) -> URLSessionTask? {
        fetch(
            api: api,
            method: method,
            request: request,
            completionQueue: DispatchQueue.main,
            completionHandler: completionHandler
        )
    }
}
