//  Created by Steven Curtis

import Foundation

public protocol APIRequest {
    associatedtype ResponseDataType
    
    func parseResponse(data: Data) throws -> ResponseDataType
    func make(
        api: URLGenerator,
        method: HTTPMethod
    ) throws -> URLRequest
}

extension APIRequest {
    public func make(api: URLGenerator, method: HTTPMethod) throws -> URLRequest {
        guard let url = api.url else {
            throw ApiError.request
        }
        var request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30.0
        )
        request.httpMethod = method.operation
        request.allHTTPHeaderFields = method.getHeaders()

        if let bearerToken = method.getToken() {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let data = method.getData() {
            let stringParams = data.parameters()
            let bodyData = stringParams.data(using: .utf8, allowLossyConversion: false)
            request.httpBody = bodyData
        }
        
        return request
    }
}
