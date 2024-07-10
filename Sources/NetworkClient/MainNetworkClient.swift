//  Created by Steven Curtis

import Foundation

public final class MainNetworkClient: NetworkClient {
    public enum TokenType {
        case bearer(token: () -> String?)
        case queryParameter(token: String)
        case requestBody(token: String)
        case customHeader(headerName: String, token: String)
    }
    private let urlSession: URLSession
    private let configuration: NetworkClientConfiguration
    private let token: TokenType?
    
    public init(
        urlSession: URLSession = .shared,
        configuration: NetworkClientConfiguration = NetworkClientConfiguration(),
        token: TokenType? = nil
    ) {
        self.urlSession = urlSession
        self.configuration = configuration
        self.token = token
    }
    
    public func fetch<T: APIRequest>(
        api: URLGenerator,
        request: T
    ) async throws -> T.ResponseDataType? {
        let urlRequest = try createURLRequest(api: api, request: request)
        let (data, response) = try await urlSession.data(for: urlRequest)
        let httpResponse = try self.handleResponse(data, response)
        try handleStatusCode(statusCode: httpResponse.statusCode)
        return httpResponse.statusCode == 204 ? nil : try parseData(data, for: request)
    }
    
    @discardableResult
    public func fetch<T: APIRequest>(
        api: URLGenerator,
        request: T,
        completionQueue: DispatchQueue,
        completionHandler: @escaping (APIResponse<T.ResponseDataType?>) -> Void
    ) -> URLSessionTask? {
        do {
            let urlRequest = try createURLRequest(
                api: api,
                request: request
            )
            let task = urlSession.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    self.completeOnQueue(
                        completionQueue,
                        with: .failure(.network(errorMessage: error.localizedDescription)),
                        completionHandler: completionHandler
                    )
                    return
                }
                
                if (response as? HTTPURLResponse)?.statusCode == 204 {
                    self.completeOnQueue(
                        completionQueue,
                        with: .success(nil),
                        completionHandler: completionHandler
                    )
                    return
                }
                
                guard let validData = data else {
                    self.completeOnQueue(
                        completionQueue,
                        with: .failure(.noData),
                        completionHandler: completionHandler
                    )
                    return
                }
                do {
                    let httpResponse = try self.handleResponse(validData, response)
                    try self.handleStatusCode(statusCode: httpResponse.statusCode)
                    let method = api.method
                    if case .delete = method {
                        self.completeOnQueue(
                            completionQueue,
                            with: .success(nil),
                            completionHandler: completionHandler
                        )
                    } else {
                        let parsedResponse = try self.parseData(validData, for: request)
                        self.completeOnQueue(
                            completionQueue,
                            with: .success(parsedResponse),
                            completionHandler: completionHandler
                        )
                    }
                } catch let apiError as APIError {
                    self.completeOnQueue(
                        completionQueue,
                        with: .failure(apiError),
                        completionHandler: completionHandler
                    )
                } catch {
                    self.completeOnQueue(
                        completionQueue,
                        with: .failure(.unknown),
                        completionHandler: completionHandler
                    )
                }
            }
            task.resume()
            return task
        } catch let apiError as APIError {
            completeOnQueue(
                completionQueue,
                with: .failure(apiError),
                completionHandler: completionHandler
            )
            return nil
        } catch {
            completeOnQueue(
                completionQueue,
                with: .failure(.unknown),
                completionHandler: completionHandler
            )
            return nil
        }
    }
    
    private func createURLRequest<T: APIRequest>(api: URLGenerator, request: T) throws -> URLRequest {
        var urlRequest = try request.make(api: api)
        if urlRequest.allHTTPHeaderFields?.count == 0 {
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
        guard let bearerToken = tokenGenerator() else {
            return
        }
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
        guard let httpBody = urlRequest.httpBody, var body = try JSONSerialization.jsonObject(
            with: httpBody,
            options: []
        ) as? [String: Any] else {
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
            let body = try? JSONSerialization.jsonObject(
                with: httpBody,
                options: []
            ) as? [String: Any]
            
            if let _ = body?["access_token"] as? String {
                 return true
            }
        }
        return false
    }

    private func applyCustomHeaderToken(_ headerName: String, _ token: String, to urlRequest: inout URLRequest) {
        urlRequest.setValue(token, forHTTPHeaderField: headerName)
    }
    
    private func handleResponse(_ data: Data, _ response: URLResponse?) throws -> (HTTPURLResponse) {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(data, response)
        }
        return httpResponse
    }
    
    private func parseData<T: APIRequest>(_ data: Data, for request: T) throws -> T.ResponseDataType {
        try request.parseResponse(data: data)
    }
    
    private func handleStatusCode(statusCode: Int) throws {
        switch statusCode {
        case 200 ..< 300:
            break
        case 400:
            throw APIError.httpError(.badRequest)
        case 401:
            throw APIError.httpError(.unauthorized)
        case 403:
            throw APIError.httpError(.forbidden)
        case 404:
            throw APIError.httpError(.notFound)
        case 500:
            throw APIError.httpError(.serverError)
        default:
            throw APIError.httpError(.unknown)
        }
    }
    
    private func completeOnQueue<T>(
        _ queue: DispatchQueue,
        with response: APIResponse<T>,
        completionHandler: @escaping (APIResponse<T>) -> Void
    ) {
        queue.async {
            completionHandler(response)
        }
    }
    
    private func applyHeaders(to request: inout URLRequest) {
        configuration.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    }
}
