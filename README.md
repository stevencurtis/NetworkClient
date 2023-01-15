# NetworkClient

A simple tested network client.

## Installation

This library supports Swift Package Manager (installation guide).

## Functionality

- Get
- Post
- Patch
- Put
- Delete
To use the network manager you must import NetworkClient at the top of the relevant class.

This provides a NetworkClient that can be stored in a property

```swift
let networkClient: NetworkClient
```

which can then be used to call the request function, which will return the response from the completion handler.

```swift
public func request<T: APIRequest>(
    api: URLGenerator,
    method: HTTPMethod,
    request: T,
    completionHandler: @escaping (ApiResponse<T.ResponseDataType>) -> Void
) -> URLSessionTask?
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
An `APIRequest` is a protocol with two functions, and is intended to parse the response and create the `URLRequest`. A default implementation for `func make(api: URLGenerator, method: HTTPMethod) throws -> URLRequest?` has been provided.

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

## Guide
There is an accompanying article on Medium to explain some of the design choices in this particular framework.
