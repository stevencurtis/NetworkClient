//  Created by Steven Curtis

import Foundation

public class MainNetworkClient: NetworkClient {
    private let urlSession: URLSession
    
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    @discardableResult
    public func request<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T,
        completionHandler: @escaping (ApiResponse<T.ResponseDataType>) -> Void
    ) -> URLSessionTask? {
        guard let urlRequest = try? request.make(api: api, method: method) else {
            completionHandler(.failure(.request))
            return nil
        }
        let task = urlSession.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completionHandler(.failure(
                    .network(errorMessage: error.localizedDescription))
                )
            }
            
            guard let data = data else { return completionHandler(.failure(.noData)) }
            do {
                let parsedResponse = try request.parseResponse(data: data)
                completionHandler(.success(parsedResponse))
            } catch {
                completionHandler(.failure(.parseResponse))
            }
        }
        task.resume()
        return task
    }
    
    public func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T
    ) async throws -> T.ResponseDataType {
        let fetchTask = Task {
            let urlRequest: URLRequest
            do {
                urlRequest = try request.make(api: api, method: method)
            } catch {
                throw ApiError.network(errorMessage: error.localizedDescription)
            }
            let (data, httpResponse) = try await urlSession.data(for: urlRequest)
            guard let httpResponse = httpResponse as? HTTPURLResponse else {
                throw ApiError.invalidResponse(data, httpResponse)
            }
            switch self.handleStatusCode(statusCode: httpResponse.statusCode) {
            case .success:
                return data
            case .failure(let error):
                throw error
            }
        }
        
        let parsedResponse = try request.parseResponse(data: try await fetchTask.value)
        return parsedResponse
    }
    
    private func handleStatusCode(statusCode: Int) -> Result<Void, ApiError> {
        switch statusCode {
        case 200 ..< 300:
            return .success(())
        case 400:
            return .failure(.httpError(.badRequest))
        case 401:
            return .failure(.httpError(.unauthorized))
        case 403:
            return .failure(.httpError(.forbidden))
        case 404:
            return .failure(.httpError(.notFound))
        case 500:
            return .failure(.httpError(.serverError))
        default:
            return .failure(.httpError(.unknown))
        }
    }
}
