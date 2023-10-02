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

extension APIRequest where ResponseDataType == Data {
    public func parseResponse(data: Data) throws -> Data {
        return data
    }
}

extension APIRequest {
    public func make(api: URLGenerator, method: HTTPMethod) throws -> URLRequest {
        guard let url = api.url else {
            throw ApiError.request
        }
        var request = createBaseRequest(url: url)
        request.httpMethod = method.operation
        request.allHTTPHeaderFields = method.getHeaders()
        setAuthorization(request: &request, method: method)
        setRequestBody(request: &request, method: method)
        return request
    }
    
    private func createBaseRequest(url: URL) -> URLRequest {
        return URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30.0
        )
    }
    
    private func setAuthorization(request: inout URLRequest, method: HTTPMethod) {
        if let bearerToken = method.getToken() {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private func setRequestBody(request: inout URLRequest, method: HTTPMethod) {
        if let data = method.getData() {
            let stringParams = data.parameters()
            let bodyData = stringParams.data(using: .utf8, allowLossyConversion: false)
            request.httpBody = bodyData
        }
    }
}
