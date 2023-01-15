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
        guard let urlRequest = try? request.make(api: api, method: method) else { return nil }
        let task = urlSession.dataTask(with: urlRequest) { data, response, error in
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
}
