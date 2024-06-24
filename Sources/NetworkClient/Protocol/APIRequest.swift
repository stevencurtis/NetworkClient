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
            throw APIError.request
        }
        var request = createBaseRequest(url: url)
        request.httpMethod = method.operation
        request.allHTTPHeaderFields = method.getHeaders()
        try setRequestBody(request: &request, method: method)
        return request
    }
    
    private func createBaseRequest(url: URL) -> URLRequest {
        return URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30.0
        )
    }
    
    private func setRequestBody(request: inout URLRequest, method: HTTPMethod) throws {
        if let body = method.getBody() {
            switch body {
            case .json(let json):
                let bodyData = try JSONSerialization.data(withJSONObject: json, options: [])
                request.httpBody = bodyData
            case .encodable(let codableBody):
                do {
                    let jsonData = try JSONEncoder().encode(codableBody)
                    request.httpBody = jsonData
                } catch {
                    throw error
                }
            }
        }
    }
}
