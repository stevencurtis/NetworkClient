# Swift NetworkClient Framework

The Swift NetworkClient Framework is a robust and simplified networking library designed to streamline HTTP requests within your Swift applications. With its intuitive API and built-in functionalities, handling HTTP methods like GET, POST, PATCH, PUT, and DELETE becomes a breeze. Whether you aim to retrieve, send, update, or delete data, this framework has got you covered.

*Key Features:*

Ease of Use: With a straightforward setup and minimal configuration, get your network operations up and running in no time.
Flexible Configuration: Tailored to meet varying demands, whether it's a simple GET request or more complex network calls.
Async Await Support: Leverage Swift's powerful async/await syntax for cleaner and more readable code.
Dependency Injection: Easily mock network responses for testing or swap out network implementations with the dependency injection support.
Error Handling: Built-in error handling functionalities to ensure smooth network operations and easier debugging.
Customizable Request and Response Parsing: Define your own request and response structures to work seamlessly with your APIs.
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
