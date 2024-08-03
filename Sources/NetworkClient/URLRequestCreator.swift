//  Created by Steven Curtis

import Foundation

public protocol URLRequestCreator {
    func createURLRequest<T: APIRequest>(api: URLGenerator, request: T) throws -> URLRequest
}

public struct URLRequestHandler: URLRequestCreator {
    private let headers: [String: String]
    private let token: TokenType?

    public init(
        headers: [String: String],
        token: TokenType? = nil
    ) {
        self.headers = headers
        self.token = token
    }

    public func createURLRequest<T: APIRequest>(api: URLGenerator, request: T) throws -> URLRequest {
        var urlRequest = try request.make(api: api)
        if urlRequest.allHTTPHeaderFields?.isEmpty ?? true {
            applyHeaders(to: &urlRequest)
        }
        if !tokenSet(to: &urlRequest) {
            try applyToken(to: &urlRequest)
        }
        return urlRequest
    }

    private func applyToken(to urlRequest: inout URLRequest) throws {
        guard let tokenType = token else { return }
        switch tokenType {
        case .bearer(let tokenGenerator):
            try applyBearerToken(tokenGenerator, to: &urlRequest)
        case .queryParameter(let token):
            try applyQueryParameterToken(token, to: &urlRequest)
        case .requestBody(let token):
            try applyRequestBodyToken(token, to: &urlRequest)
        case .customHeader(let headerName, let token):
            applyCustomHeaderToken(headerName, token, to: &urlRequest)
        }
    }

    private func applyBearerToken(_ tokenGenerator: () -> String?, to urlRequest: inout URLRequest) throws {
        guard let bearerToken = tokenGenerator() else { return }
        urlRequest.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    }

    private func applyQueryParameterToken(_ token: String, to urlRequest: inout URLRequest) throws {
        guard let request = urlRequest.url, var urlComponents = URLComponents(url: request, resolvingAgainstBaseURL: false), var queryItems = urlComponents.queryItems else {
            throw APIError.generalToken
        }
        queryItems.append(URLQueryItem(name: "access_token", value: token))
        urlComponents.queryItems = queryItems
        urlRequest.url = urlComponents.url
    }

    private func applyRequestBodyToken(_ token: String, to urlRequest: inout URLRequest) throws {
        guard let httpBody = urlRequest.httpBody, var body = try JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any] else {
            throw APIError.generalToken
        }
        body["access_token"] = token
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    }

    private func tokenSet(to urlRequest: inout URLRequest) -> Bool {
        if urlRequest.value(forHTTPHeaderField: "Authorization") != nil {
            return true
        }
        
        if let request = urlRequest.url, let urlComponents = URLComponents(url: request, resolvingAgainstBaseURL: false), let queryItems = urlComponents.queryItems {
            if queryItems.contains(where: { $0.name == "access_token" }) {
                return true
            }
        }
        
        if let httpBody = urlRequest.httpBody {
            let body = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any]
            if body?["access_token"] as? String != nil {
                return true
            }
        }
        return false
    }

    private func applyCustomHeaderToken(_ headerName: String, _ token: String, to urlRequest: inout URLRequest) {
        urlRequest.setValue(token, forHTTPHeaderField: headerName)
    }

    private func applyHeaders(to request: inout URLRequest) {
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    }
}
