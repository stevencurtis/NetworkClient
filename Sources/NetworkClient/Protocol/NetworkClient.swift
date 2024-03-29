//  Created by Steven Curtis

import Foundation

public protocol NetworkClient {
    @discardableResult
    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T,
        completionQueue: DispatchQueue,
        completionHandler: @escaping (APIResponse<T.ResponseDataType?>) -> Void
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
        completionQueue: DispatchQueue = DispatchQueue.main,
        completionHandler: @escaping (APIResponse<T.ResponseDataType?>) -> Void
    ) -> URLSessionTask? {
        fetch(
            api: api,
            method: method,
            request: request,
            completionQueue: completionQueue,
            completionHandler: completionHandler
        )
    }
    
    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T = DefaultRequest()
    ) async throws -> T.ResponseDataType? {
        try await fetch(
            api: api,
            method: method,
            request: request
        )
    }
}
