//  Created by Steven Curtis

import Foundation

public final class MainNetworkClient: NetworkClient {
    private let configuration: NetworkClientConfiguration
    
    public init(
        configuration: NetworkClientConfiguration = NetworkClientConfiguration.make()
    ) {
        self.configuration = configuration
    }
    
    public func fetch<T: APIRequest>(
        api: URLGenerator,
        request: T
    ) async throws -> T.ResponseDataType? {
        let urlRequest = try configuration.urlRequestCreator.createURLRequest(api: api, request: request)
        do {
            let (data, response) = try await configuration.urlSession.data(for: urlRequest)
            let httpResponse = try configuration.errorHandler.handleResponse(data, response)
            try configuration.errorHandler.handleStatusCode(statusCode: httpResponse.statusCode)
            return httpResponse.statusCode == 204 ? nil : try configuration.dataParser.parseData(data, for: request)
        }  catch URLError.notConnectedToInternet {
            throw APIError.network(errorMessage: "No internet connection")
        } catch URLError.timedOut {
            throw APIError.network(errorMessage: "The request timed out")
        } catch {
            throw APIError.unknown
        }
    }
    
    @discardableResult
    public func fetch<T: APIRequest>(
        api: URLGenerator,
        request: T,
        completionQueue: DispatchQueue,
        completionHandler: @escaping (APIResponse<T.ResponseDataType?>) -> Void
    ) -> URLSessionTask? {
        do {
            let urlRequest = try configuration.urlRequestCreator.createURLRequest(
                api: api,
                request: request
            )
            let task = configuration.urlSession.dataTask(with: urlRequest) { data, response, error in
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
                    let httpResponse = try self.configuration.errorHandler.handleResponse(validData, response)
                    try self.configuration.errorHandler.handleStatusCode(statusCode: httpResponse.statusCode)
                    let method = api.method
                    if case .delete = method {
                        self.completeOnQueue(
                            completionQueue,
                            with: .success(nil),
                            completionHandler: completionHandler
                        )
                    } else {
                        let parsedResponse = try self.configuration.dataParser.parseData(validData, for: request)
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
