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
    private let token: TokenType?
    
    public init(urlSession: URLSession = .shared, token: TokenType? = nil) {
        self.urlSession = urlSession
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
        let method = api.method
        var urlRequest = try request.make(api: api, method: method)
        if let token = token {
            switch token {
            case .bearer(let bearerTokenFunction):
                guard let bearerToken = bearerTokenFunction() else {
                    throw APIError.bearerToken
                }
                urlRequest.setValue(
                    "Bearer \(bearerToken)",
                    forHTTPHeaderField: "Authorization"
                )
            case .queryParameter(let queryToken):
                guard let request = urlRequest.url, var urlComponents = URLComponents(
                    url: request,
                    resolvingAgainstBaseURL: false
                ), var queryItems = urlComponents.queryItems else {
                    throw APIError.generalToken
                }
                queryItems.append(
                    URLQueryItem(
                        name: "access_token",
                        value: queryToken
                    )
                )
                urlComponents.queryItems = queryItems
                urlRequest.url = urlComponents.url
            case .requestBody(let bodyToken):
                guard let httpBody = urlRequest.httpBody,  var body = try JSONSerialization.jsonObject(
                    with: httpBody,
                    options: []
                ) as? [String: Any] else {
                    throw APIError.generalToken
                }
                body["access_token"] = bodyToken
                urlRequest.httpBody = try JSONSerialization.data(
                    withJSONObject: body,
                    options: []
                )
                urlRequest.setValue(
                    "application/json",
                    forHTTPHeaderField: "Content-Type"
                )
            case .customHeader(let headerName, let customToken):
                urlRequest.setValue(customToken, forHTTPHeaderField: headerName)
            }
        }
        return urlRequest
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
}
