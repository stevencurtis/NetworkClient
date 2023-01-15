//  Created by Steven Curtis

import Foundation

public protocol APIRequest {
    associatedtype ResponseDataType
    
    func parseResponse(data: Data) throws -> ResponseDataType
    func make(
        api: URLGenerator,
        method: HTTPMethod
    ) throws -> URLRequest?
}

extension APIRequest {
    public func make(api: URLGenerator, method: HTTPMethod) throws -> URLRequest? {
        guard let url = api.url else { return nil }
        var request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30.0
        )
        request.httpMethod = method.operation
        return request
    }
}
