//  Created by Steven Curtis

import Foundation

public protocol APIRequest {
    associatedtype ResponseDataType
    var body: HTTPBody? { get }
    func parseResponse(data: Data) throws -> ResponseDataType
    func make(
        api: URLGenerator
    ) throws -> URLRequest
}

extension APIRequest where ResponseDataType == Data {
    public func parseResponse(data: Data) throws -> Data {
        return data
    }
}

extension APIRequest {
    var body: HTTPBody? { nil }
    public func make(api: URLGenerator) throws -> URLRequest {
        guard let url = api.url else {
            throw APIError.request
        }
        var request = createBaseRequest(url: url)
        request.httpMethod = api.method.operation
        try setRequestBody(request: &request, body: body)
        return request
    }
    
    private func createBaseRequest(url: URL) -> URLRequest {
        return URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30.0
        )
    }
    
    private func setRequestBody(request: inout URLRequest, body: HTTPBody?) throws {
        guard let body else { return }
        switch body {
        case .json(let json):
            let bodyData = try JSONSerialization.data(withJSONObject: json, options: [])
            request.httpBody = bodyData
        case .encodable(let encodableBody):
            let jsonData = try JSONEncoder().encode(encodableBody)
            request.httpBody = jsonData
        }
    }
}
