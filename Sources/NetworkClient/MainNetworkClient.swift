//  Created by Steven Curtis

import Foundation

public class MainNetworkClient: NetworkClient {
    private let urlSession: URLSession
    
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    public func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T
    ) async throws -> T.ResponseDataType {
        let urlRequest = try createURLRequest(api: api, method: method, request: request)
        let (data, response) = try await urlSession.data(for: urlRequest)
        let httpResponse = try self.handleResponse(data, response)
        try handleStatusCode(statusCode: httpResponse.statusCode)
        return try parseData(data, for: request)
    }

    @discardableResult
    public func request<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T,
        completionHandler: @escaping (ApiResponse<T.ResponseDataType>) -> Void
    ) -> URLSessionTask? {
        do {
            let urlRequest = try createURLRequest(api: api, method: method, request: request)
            let task = urlSession.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    completionHandler(.failure(.network(errorMessage: error.localizedDescription)))
                    return
                }
                guard let validData = data else {
                    completionHandler(.failure(.noData))
                    return
                }
                do {
                    let httpResponse = try self.handleResponse(validData, response)
                    try self.handleStatusCode(statusCode: httpResponse.statusCode)
                    let parsedResponse = try self.parseData(validData, for: request)
                    completionHandler(.success(parsedResponse))
                } catch let apiError as ApiError {
                    completionHandler(.failure(apiError))
                } catch {
                    completionHandler(.failure(.unknown))
                }
            }
            task.resume()
            return task
        } catch let apiError as ApiError {
            completionHandler(.failure(apiError))
            return nil
        } catch {
            completionHandler(.failure(.unknown))
            return nil
        }
    }
    
    private func createURLRequest<T: APIRequest>(api: URLGenerator, method: HTTPMethod, request: T) throws -> URLRequest {
        let urlRequest = try request.make(api: api, method: method)
        return urlRequest
    }

    private func handleResponse(_ data: Data, _ response: URLResponse?) throws -> (HTTPURLResponse) {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse(data, response)
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
            throw ApiError.httpError(.badRequest)
        case 401:
            throw ApiError.httpError(.unauthorized)
        case 403:
            throw ApiError.httpError(.forbidden)
        case 404:
            throw ApiError.httpError(.notFound)
        case 500:
            throw ApiError.httpError(.serverError)
        default:
            throw ApiError.httpError(.unknown)
        }
    }
}
