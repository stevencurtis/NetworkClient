# Swift NetworkClient Framework

The Swift NetworkClient Framework is a robust and simplified networking library designed to streamline HTTP requests within your Swift applications. With its intuitive API and built-in functionalities, handling HTTP methods like GET, POST, PATCH, PUT, and DELETE becomes a breeze. Whether you aim to retrieve, send, update, or delete data, this framework has got you covered.

*Key Features:*

Ease of Use: With a straightforward setup and minimal configuration, get your network operations up and running in no time.
Flexible Configuration: Tailored to meet varying demands, whether it's a simple GET request or more complex network calls.
Async Await Support: Leverage Swift's powerful async/await syntax for cleaner and more readable code.
Dependency Injection: Easily mock network responses for testing or swap out network implementations with the dependency injection support.
Error Handling: Built-in error handling functionalities to ensure smooth network operations and easier debugging.
Customisable Request and Response Parsing: Define your own request and response structures to work seamlessly with your APIs.
Swift Package Manager Support: Effortless integration into your projects with Swift Package Manager.

## Installation

This library supports Swift Package Manager ([installation guide](https://stevenpcurtis.medium.com/use-swift-package-manager-to-add-dependencies-b605f91a4990)).

## Functionality

**Supported API Requests**
- Get
- Post
- Patch
- Put
- Delete

## Usage

**Within your class**
To use the network manager you must import the framework with `import NetworkClient` at the top of the relevant class.

This provides a NetworkClient that can be stored in a property, or use dependency injection to either mock `URLSession` or mock the entire network client yourself depending on your use case.

Your view model may well have the following initializer:

```swift
let networkClient: NetworkClient
init(
    networkClient: NetworkClient = MainNetworkClient()
) {
    self.networkClient = networkClient
}
```

The property can then be used to call the request function, which will return the response from the completion handler. There is also a async version which can be used depending on your use case.

```swift
    @discardableResult
    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T,
        completionQueue: DispatchQueue,
        completionHandler: @escaping (ApiResponse<T.ResponseDataType?>) -> Void
    ) -> URLSessionTask?

    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T
    ) async throws -> T.ResponseDataType?
```

**URLGenerator**
This is a protocol that has a property for a `URL`

```swift
public protocol URLGenerator {
    var url: URL? { get }
}
```

an `enum` conforming to the protocol might look something like the following in order to construct a `URL`:

```swift
enum Api: URLGenerator {
    case list
    case images(breed: Breed)
    var url: URL? {
        var component = URLComponents()
        component.scheme = "https"
        component.host = "dog.ceo"
        component.path = path
        return component.url
    }
}
``` 
**APIRequest**
An `APIRequest` is a protocol with two functions, and is intended to parse the response and create the `URLRequest`. A default implementation for both functions has been provided, and can be used by deciding to not provide a request when calling fetch.

```swift
public protocol APIRequest {
    associatedtype ResponseDataType
    
    func parseResponse(data: Data) throws -> ResponseDataType
    func make(
        api: URLGenerator,
        method: HTTPMethod
    ) throws -> URLRequest?
}

extension APIRequest {
    public func make(api: URLGenerator, method: HTTPMethod) throws -> URLRequest? {
        guard let url = api.url else { return nil }
        var request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30.0
        )
        request.httpMethod = method.operation
        return request
    }
}
```

A typical concrete implementation of a request might look something like the following:

```swift
struct DogRequest: APIRequest {
    func parseResponse(data: Data) throws -> BreedsListApiDto {
        let decoder = JSONDecoder()
        return try decoder.decode(BreedsListApiDto.self, from: data)
    }
}
```

## Error Handling
The Swift NetworkClient Framework prioritizes robust error handling to ensure smooth network operations and easier debugging. Here's how it manages errors:

Defining Error Types:
The framework defines a custom error type ApiError to encapsulate common HTTP errors and other network-related errors.

```swift
enum ApiError: Error {
    case httpError(HttpError)
    case network(errorMessage: String)
    case noData
    case invalidResponse(Data?, URLResponse?)
    case unknown
}
```

Handling HTTP Status Codes:
The handleStatusCode function evaluates the HTTP status code returned with the response, and throws relevant errors based on the status code.
```swift
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
```

Handling Network Response:
The handleResponse function checks if the response is of type HTTPURLResponse and throws an invalidResponse error if not.

```swift
private func handleResponse(_ data: Data, _ response: URLResponse?) throws -> (HTTPURLResponse) {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw ApiError.invalidResponse(data, response)
    }
    return httpResponse
}
```

Error Propagation:
Errors are propagated back to the calling function, allowing for centralized error handling. This allows for cleaner code and easier debugging.

```swift
do {
    let httpResponse = try self.handleResponse(validData, response)
    try self.handleStatusCode(statusCode: httpResponse.statusCode)
    //...
} catch let apiError as ApiError {
    // Handle ApiError
} catch {
    // Handle other errors
}
```

In the closure version of the fetch function, errors are propagated back through the completionHandler closure, allowing for centralized error handling within the closure.

Whenever an error occurs, whether it's a network error, an HTTP error, or any other type of error, it's wrapped in an ApiResponse enum and passed to the completionHandler through the completeOnQueue function. This way, the caller can handle the error in the completionHandler block, allowing for a structured and centralized error handling strategy.

## Guide
There is an accompanying article on Medium to explain some of the design choices in this particular framework.

(Not yet available)

# Write a Swift Network Layer
## It's pretty good
I produced a [network client](https://github.com/stevencurtis/NetworkClient) that I'm going to use for all of my personal projects going forwards. Instead of using a third-party framework it's great to understand networking in Swift and create your own (in my opinion). This article explains and documents it. I hope this article helps somebody reading!

Difficulty: Beginner | Easy | *Normal* | Challenging
This article has been developed using Xcode 15.2, and Swift 5.9

## Prerequisites:
To install the network manager to which this refers, you will need to know something about [Swift Package Manager](https://stevenpcurtis.medium.com/create-a-swift-package-in-xcode-e7700adf7a7d)
Having a handle on [generics](https://betterprogramming.pub/generics-in-swift-aa111f1c549) will also help you out.

# Installation
If you wish to use this network manager you can (in Xcode) go to your project and add it as a package dependency. The location is https://github.com/stevencurtis/NetworkClient and the current version is 0.0.11.

# The public API
There are two entry points for this network manager — both AnyNetworkManager and NetworkManager are publicly accessible. Not only that - there is a MockNetworkManager that is publicly available for testing.

## Network Manager
Let us first look at NetworkManager. Let us take a look at the exposed protocol:

```swift
import Foundation

public protocol NetworkClient {
    @discardableResult
    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T,
        completionQueue: DispatchQueue,
        completionHandler: @escaping (APIResponse<T.ResponseDataType?>) -> Void
    ) -> URLSessionTask?

    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T
    ) async throws -> T.ResponseDataType?
}

public extension NetworkClient {
    @discardableResult
    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T = DefaultRequest(),
        completionQueue: DispatchQueue = DispatchQueue.main,
        completionHandler: @escaping (APIResponse<T.ResponseDataType?>) -> Void
    ) -> URLSessionTask? {
        fetch(
            api: api,
            method: method,
            request: request,
            completionQueue: completionQueue,
            completionHandler: completionHandler
        )
    }
    
    func fetch<T: APIRequest>(
        api: URLGenerator,
        method: HTTPMethod,
        request: T = DefaultRequest()
    ) async throws -> T.ResponseDataType? {
        try await fetch(
            api: api,
            method: method,
            request: request
        )
    }
}
```

which I can then access in my main parent project with `MainNetworkClient()`, providing I remember to `import NetworkClient`. 

**Understanding the NetworkClient Protocol**
The `NetworkClient` protocol serves as the foundation of the Swift `NetworkClient` Framework, outlining the essential methods required for executing network requests. By adhering to this protocol, the framework offers a unified and simplified approach to network communications, ensuring consistency and reliability across different parts of an application.

- Asynchronous Fetch Method -

The asynchronous fetch method utilizes Swift’s async/await syntax, offering a more streamlined way to handle network requests and responses. This method is designed to simplify the codebase, reducing the complexity associated with managing asynchronous code and completion handlers.

- Completion Handler Fetch Method -

In contrast, the completion handler variant of the fetch method provides a more traditional approach to asynchronous programming. This method allows developers to handle the response and any potential errors within a completion block, offering flexibility in how responses are processed and errors are handled.

This of course calls a concrete network client.

##MainNetworkClient

```swift
public final class MainNetworkClient: NetworkClient {
    private let urlSession: URLSession
    
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
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
```

**Understanding the Main Network client**

The `MainNetworkClient` class encapsulates the concrete implementation of the `NetworkClient` protocol within the Swift `NetworkClient` Framework. By leveraging the power of Swift’s modern features such as generics, async/await, and closures, `MainNetworkClient` offers a flexible and efficient way to handle network requests. This class simplifies the complexity of networking operations while providing robust error handling and response parsing capabilities.

** Core Components**
- URLSession Dependency -

At its core, `MainNetworkClient` utilizes `URLSession`, Swift's native API for networking, to perform HTTP requests. The flexibility to inject a `URLSession` instance during initialization enables easy testing and customization, allowing developers to use a shared session for simplicity or a custom session configuration tailored to specific requirements.

- Error Handling -

MainNetworkClient introduces a comprehensive error handling system, capable of distinguishing between various error types including HTTP errors, network errors, and unexpected conditions. This system ensures that errors are not only caught but also categorized for appropriate handling or messaging.

- Simplifying Network Requests -
By relying on the APIRequest protocol, `MainNetworkClient` delegates the responsibilities of request creation and response parsing to the conforming types. This separation of concerns allows for more manageable code, where each request can specify its own parsing logic and URL construction.

This means simple network requests can be formed using a typealias:

```swift
typealias CommentRequest = BasicRequest<[Comment]>
```

where `Comment` is any type conforming to [`Decodable`](https://stevenpcurtis.medium.com/using-codable-with-nested-json-you-can-2d5a891d40c3)

due to `BasicRequest` being provided in the network client library

```swift
public struct BasicRequest<T: Decodable>: APIRequest {
    public typealias ResponseDataType = T
    public init() { }
    public func parseResponse(data: Data) throws -> ResponseDataType {
        let decoder = JSONDecoder()
        return try decoder.decode(ResponseDataType.self, from: data)
    }
}
```

** Unified Approach to Networking **
The design of `MainNetworkClient` represents a unified approach to networking in Swift applications. By abstracting away the underlying complexities of making network requests and parsing responses, it enables developers to focus more on their application’s logic rather than the intricacies of networking.

** The HTTPMethod **
The network client expects the caller to use the classic HTTP method requests. The  GET, POST, PUT, DELETE, and PATCH methods can be called  along with support for custom headers, and request bodies as necessary.

```swift
public enum HTTPMethod {
    case get(headers: [String : String] = [:], token: String? = nil)
    case post(headers: [String : String] = [:], token: String? = nil, body: [String: Any])
    case put(headers: [String : String] = [:], token: String? = nil)
    case delete(headers: [String : String] = [:], token: String? = nil)
    case patch(headers: [String : String] = [:], token: String? = nil)
}

extension HTTPMethod: CustomStringConvertible {
    public var operation: String {
        return self.description
    }
    
    public var description: String {
        switch self {
            case .get:
                return "GET"
            case .post:
                return "POST"
            case .put:
                return "PUT"
            case .delete:
                return "DELETE"
            case .patch:
                return "PATCH"
        }
    }
    
    func getHeaders() -> [String: String]? {
        switch self {
        case .get(headers: let headers, _):
            return headers
        case .post(headers: let headers, _, body: _):
            return headers
        case .put(headers: let headers, _):
            return headers
        case .delete(headers: let headers, _):
            return headers
        case .patch(headers: let headers, _):
            return headers
        }
    }
    
    func getToken() -> String? {
        switch self {
        case .get(_, token: let token):
            return token
        case .post(_, token: let token, body: _):
            return token
        case .put(_, token: let token):
            return token
        case .delete(_, token: let token):
            return token
        case .patch(_, token: let token):
            return token
        }
    }
    
    func getData() -> [String: Any]? {
        switch self {
        case .get:
            return nil
        case .post( _, _, body: let body):
            return body
        case .put:
            return nil
        case .delete:
            return nil
        case .patch:
            return nil
        }
    }
}
```

** The APIRequest **
The `APIRequest` protocol standardizes the way network requests are created and responses are parsed. It ensures that any network call adheres to a consistent structure, thereby simplifying the implementation of network operations across different parts of an application.

Protocol signature:

```swift
public protocol APIRequest {
    associatedtype ResponseDataType
    
    func parseResponse(data: Data) throws -> ResponseDataType
    func make(
        api: URLGenerator,
        method: HTTPMethod
    ) throws -> URLRequest
}
```

which has the following extensions to enhance ease of use for users of the framework.

```swift
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
        setAuthorization(request: &request, method: method)
        setRequestBody(request: &request, method: method)
        return request
    }
    
    private func createBaseRequest(url: URL) -> URLRequest {
        return URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30.0
        )
    }
    
    private func setAuthorization(request: inout URLRequest, method: HTTPMethod) {
        if let bearerToken = method.getToken() {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private func setRequestBody(request: inout URLRequest, method: HTTPMethod) {
        if let data = method.getData() {
            let stringParams = data.parameters()
            let bodyData = stringParams.data(using: .utf8, allowLossyConversion: false)
            request.httpBody = bodyData
        }
    }
}
```

The `parseResponse(data:)` function is responsible for parsing the response data received from the network call into a specific data model that the application can work with. This function uses Swift's powerful `Decodable` protocol to decode the response data into a specified type, ensuring type safety and reducing the risk of runtime errors. 

The `make(api:method:)` function, on the other hand, is tasked with creating a `URLRequest` configured with the appropriate API endpoint, HTTP method, and headers. This function allows for a high degree of customisation, enabling developers to tailor the request to meet the specific requirements of the API they are interacting with.

A typical concrete implementation might look like the following:

```swift
struct DogRequest: APIRequest {
    func parseResponse(data: Data) throws -> BreedsListApiDto {
        let decoder = JSONDecoder()
        return try decoder.decode(BreedsListApiDto.self, from: data)
    }
}
```

** URLGenerator **
This is a protocol designed to abstract the creation of URLs for network requests. Conforming types can encapsulate the logic required to construct URLs dynamically making the process of generating URLs for different endpoints structured and maintainable.

```swift
public protocol URLGenerator {
    var url: URL? { get }
}
```

The protocol itself describes url that is a computed property that returns an optional `URL` instance.

A concrete example of this looks like the following:

```swift
enum Api: URLGenerator {
    case list
    case images(breed: Breed)
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "dog.ceo"
        components.path = path
        return components.url
    }
}

extension Api {
    fileprivate var path: String {
        switch self {
        case .list:
            return "/api/breeds/list/all"
        case .images(let breed):
            if let subBreed = breed.sub {
                return "/api/breed/\(breed.master)/\(subBreed)/images/random/10"
            }
            return "/api/breed/\(breed.master)/images/random/10"
        }
    }
}
```

Leveraging `URLGenerator` in your application could look something like this, providing a clear, type-safe pathway to making network requests:

```swift
try await networkClient.fetch(api: Api.list, method: .get(), request: dogRequest)
```

# Testing
To test the network client `XCTest` and a custom mock URL protocol are used to avoid setting up a network dependency.

Configuring a `URLSession` with a mock session configuration is crucial for intercepting network requests and providing predefined responses without hitting an actual network.

```swift
override func setUp() {
    super.setUp()
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let mockSession = URLSession(configuration: configuration)
    networkClient = MainNetworkClient(urlSession: mockSession)
}
```

For asynchronous operations, expectation is used to wait for completion before making assertions. Tests are isolated and do not depend on the outcome of another test. Most edge cases are covered with the following tests.

```swift
@testable import NetworkClient
import XCTest

final class NetworkClientTests: XCTestCase {
    private var networkClient: NetworkClient!
    private let request = MockRequest()
    private let queue = DispatchQueue(label: "NetworkClientTests")

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: configuration)
        networkClient = MainNetworkClient(urlSession: mockSession)
    }
    
    override func tearDown() {
        networkClient = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    func testFetchGet_successfullyParsesExpectedJSONData() throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(statusCode: 200, data: mockJSONData)
        let expectation = expectation(description: "NetworkClient fetch expectation")

        let expected = MockDto(message: "testdata")
        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .get(),
            request: request,
            completionQueue: queue) { response in
                switch response {
                case .success(let list):
                    XCTAssertEqual(list, expected)
                case .failure:
                    XCTFail()
                }
                expectation.fulfill()
            }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchPost_handlesSuccessResponse() throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        setupMockResponse(statusCode: 201, data: mockJSONData)
        let expectation = expectation(description: "NetworkClient fetch expectation")

        let expected = MockDto(message: "success")
        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .post(body: ["text":"text"]),
            request: request,
            completionQueue: queue
        ) { response in
            switch response {
            case .success(let list):
                XCTAssertEqual(list, expected)
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchPut_handlesSuccessResponse() throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        setupMockResponse(statusCode: 200, data: mockJSONData)
        let expectation = expectation(description: "NetworkClient fetch expectation")

        let expected = MockDto(message: "success")
        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .put(),
            request: request,
            completionQueue: queue
        ) { response in
            switch response {
            case .success(let list):
                XCTAssertEqual(list, expected)
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchDelete_handlesSuccessResponse() throws {
        setupMockResponse(statusCode: 204)
        let expectation = expectation(description: "NetworkClient fetch expectation")

        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .delete(),
            request: request,
            completionQueue: queue
        ) { response in
            switch response {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchDeleteDefaultRequest_handlesSuccessResponse() throws {
        setupMockResponse(statusCode: 204)
        let expectation = expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .delete(),
            completionQueue: queue
        ) { response in
            switch response {
            case .success:
                break
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchPatch_handlesSuccessResponse() throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        setupMockResponse(statusCode: 200, data: mockJSONData)

        let expected = MockDto(message: "success")
        let expectation = expectation(description: "NetworkClient fetch expectation")

        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .patch(),
            request: request,
            completionQueue: queue
        ) { response in
            switch response {
            case .success(let list):
                XCTAssertEqual(list, expected)
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchGet_handlesInvalidResponseData() throws {
        setupMockResponse()

        let expectation = expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: MockAPI.endpoint, method: .get(), request: request, completionQueue: queue) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .parseResponse(errorMessage: "The data couldn’t be read because it isn’t in the correct format."))
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchGet_handlesBadRequestError() throws {
        setupMockResponse(statusCode: 400)

        let expectation = expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: MockAPI.endpoint, method: .get(), request: request, completionQueue: queue) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.badRequest))
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

    }

    func testFetchGet_handlesUnauthorizedError() throws {
        setupMockResponse(statusCode: 401)

        let expectation = expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .get(),
            request: request,
            completionQueue: queue
        ) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.unauthorized))
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchGet_handlesForbiddenError() throws {
        setupMockResponse(statusCode: 403)

        let expectation = expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .get(),
            request: request,
            completionQueue: queue
        ) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.forbidden))
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchGet_handlesNotFoundError() throws {
        setupMockResponse(statusCode: 404)

        let expectation = expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .get(),
            request: request,
            completionQueue: queue
        ) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.notFound))
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchGet_handlesServerError() throws {
        setupMockResponse(statusCode: 500)

        let expectation = expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .get(),
            request: request,
            completionQueue: queue
        ) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.serverError))
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchGetAsync_successfulDataFetch() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        let expected = MockDto(message: "testdata")
        setupMockResponse(statusCode: 200, data: mockJSONData)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .get(),
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchPostAsync_successfulDataFetch() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        let expected = MockDto(message: "success")
        setupMockResponse(statusCode: 200, data: mockJSONData)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .post(body: [:]),
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchPutAsync_successfulDataFetch() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        let expected = MockDto(message: "success")
        setupMockResponse(statusCode: 200, data: mockJSONData)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .put(),
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchPatchAsync_successfulDataFetch() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        let expected = MockDto(message: "success")
        setupMockResponse(statusCode: 200, data: mockJSONData)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .patch(),
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchDeleteAsync_successfulDataFetch() async throws {
        setupMockResponse(statusCode: 204)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .delete(),
            request: request
        )
        XCTAssertEqual(data, nil)
    }
    
    func testFetchDeleteAsyncNoRequest_successfulDataFetch() async throws {
        setupMockResponse(statusCode: 204)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .delete()
        )
        XCTAssertEqual(data, nil)
    }

    func testFetchGetAsync_handlesInvalidData() async throws {
        let mockJSONData = try XCTUnwrap("{\"notamessage\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(data: mockJSONData)

        do {
            _ = try await networkClient.fetch(
                api: MockAPI.endpoint,
                method: .get(),
                request: request
            )
        } catch let error {
            guard let apiError = error as? APIError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .parseResponse(errorMessage: "The data couldn’t be read because it is missing."))
        }
    }

    func testFetchGetAsync_handlesBadRequestError() async throws {
        setupMockResponse(statusCode: 400)
        do {
            _ = try await networkClient.fetch(
                api: MockAPI.endpoint,
                method: .get(),
                request: request
            )
        } catch let error {
            guard let apiError  = error as? APIError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.badRequest))
        }
    }

    func testFetchGetAsync_handlesUnauthorizedError() async throws {
        setupMockResponse(statusCode: 401)
        do {
            _ = try await networkClient.fetch(
                api: MockAPI.endpoint,
                method: .get(),
                request: request
            )
        } catch let error {
            guard let apiError  = error as? APIError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.unauthorized))
        }
    }

    func testFetchGetAsync_handlesForbiddenError() async throws {
        setupMockResponse(statusCode: 403)
        do {
            _ = try await networkClient.fetch(
                api: MockAPI.endpoint,
                method: .get(),
                request: request
            )
        } catch let error {
            guard let apiError  = error as? APIError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.forbidden))
        }
    }

    func testFetchGetAsync_handlesNotFoundError() async throws {
        setupMockResponse(statusCode: 404)
        do {
            _ = try await networkClient.fetch(
                api: MockAPI.endpoint,
                method: .get(),
                request: request
            )
        } catch let error {
            guard let apiError  = error as? APIError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.notFound))
        }
    }

    func testFetchGetAsync_handlesServerError() async throws {
        setupMockResponse(statusCode: 500)
        do {
            _ = try await networkClient.fetch(
                api: MockAPI.endpoint,
                method: .get(),
                request: request
            )
        } catch let error {
            guard let apiError  = error as? APIError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.serverError))
        }
    }

    func testFetchGetAsync_handlesUnknownError() async throws {
        setupMockResponse(statusCode: 600)
        do {
            _ = try await networkClient.fetch(
                api: MockAPI.endpoint,
                method: .get(),
                request: request
            )
        } catch let error {
            guard let apiError  = error as? APIError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.unknown))
        }
    }
}

extension NetworkClientTests {
    private func setupMockResponse(
        statusCode: Int? = nil,
        data: Data = Data()
    ) {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                XCTFail("Request URL is nil")
                return (HTTPURLResponse(), Data())
            }
            
            if let statusCode = statusCode,
               let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: [:]
               ) {
                return (response, data)
            } else {
                let response = HTTPURLResponse()
                return (response, data)
            }
        }
    }
}
```

## Helpers

```swift
struct TestModel: Decodable {
    let id: Int
    let name: String
}
```

## Mocks
Mocks are used to avoid to help isolate the behaviour of individual modules and components, as well as ensuring tests run quickly by avoiding waiting for real objects to respond.

** MockAPI **
```swift
enum MockAPI: URLGenerator {
    case endpoint
    
    var url: URL? {
        var component = URLComponents()
        component.scheme = "https"
        component.host = "endpoint"
        component.path = "/path/"
        return component.url
    }
}
```

** MockRequest **
```swift
struct MockRequest: APIRequest {
    func parseResponse(data: Data) throws -> MockDto? {
        let decoder = JSONDecoder()
        do {
            let dto = try decoder.decode(MockDto.self, from: data)
            return dto
        } catch let error {
            throw APIError.parseResponse(errorMessage: error.localizedDescription)
        }
    }
}

struct MockDto: Decodable, Equatable {
    let message: String
}
```

** MockURLGenerator **
```swift
struct MockURLGenerator: URLGenerator {
    var url: URL? = URL(string: "https://www.google.com")
}
```

** MockURLProtocol **
```swift
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() { }
}
```

# Conclusion
This network client is designed to offer a adaptable approach to handling networking for Swift applications. By abstracting away the complexities of direct HTTP request handling and offering a suite of customizable features, it significantly reduces the boilerplate code needed to implement networking functionality.

From making simple GET requests to handling more complex network operations with async/await support, this is the network client I'm going to use with my home projects rather than commercial or other third-party frameworks.
