//  Created by Steven Curtis

import Foundation

public final class MainNetworkClient: NetworkClient {
    private let urlSession: URLSession
    private let testClosure: (statusCode: Int, api: URLGenerator, method: HTTPMethod, success: () -> (), (Data) -> Bool)?
    public init(
        urlSession: URLSession = .shared,
        testClosure: (statusCode : Int, api: URLGenerator, method: HTTPMethod, success: () -> (), (Data) -> Bool)? = nil
    ) {
        self.urlSession = urlSession
        self.testClosure = testClosure
    }
    
    public func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T
    ) async throws -> T.ResponseDataType? {
        
        let urlRequest = try createURLRequest(api: api, method: method, request: request)
        let (data, response) = try await urlSession.data(for: urlRequest)
        let httpResponse = try self.handleResponse(data, response)
        try handleStatusCode(statusCode: httpResponse.statusCode)
//        if let testClosure = testClosure, statusCode == testClosure.0 {

        // this will never work because we can have multiple requests for the refresh token using old and new tokens, it's a mess. The only solution is probably to use a token manager that returns a usable token
        
        if let testClosure = testClosure, httpResponse.statusCode == 403 {
            let storedMethod = method
            method.with(token: "")
            // how to change the token?
//            fetch(api: testClosure.api,
//                  method: testClosure.method,
//                  completionHandler: { data in try! testClosure.4(
//                   data.result.get()!!
//                )
//            })
            
            let data = try await fetch(api: testClosure.api, method: testClosure.method)
            if testClosure.4(data!) {
                
                // successfully retrieved token. Try again
                // need to use the updated token here of course
//                let (data, response) = try await urlSession.data(for: storedRequest)
//                let httpResponse = try self.handleResponse(data, response)
//                try handleStatusCode(statusCode: httpResponse.statusCode)
//                return httpResponse.statusCode == 204 ? nil : try parseData(data, for: request)
                
                
                // Instead of getting bogged down here woe could produce a specific error and let the caller handle this (for now)
                throw APIError.httpError(.unknown)
            } else {
                // did not retrieve token. error
            }
            // Make sure that we do not have multiple fetch while retrieving the token (how)
        }
        return httpResponse.statusCode == 204 ? nil : try parseData(data, for: request)
    }
    
    @discardableResult
    public func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T,
        completionQueue: DispatchQueue,
        completionHandler: @escaping (APIResponse<T.ResponseDataType?>) -> Void
    ) -> URLSessionTask? {
        do {
            let urlRequest = try createURLRequest(
                api: api,
                method: method,
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
    
    private func createURLRequest<T: APIRequest>(api: URLGenerator, method: HTTPMethod, request: T) throws -> URLRequest {
        let urlRequest = try request.make(api: api, method: method)
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
//            throw APIError.httpError(.forbidden)
            break
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
