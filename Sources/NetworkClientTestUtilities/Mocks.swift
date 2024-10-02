import NetworkClient

public protocol MockResult {
    associatedtype DataType
    func getResult() throws -> DataType?
}

public struct MockSuccess<T>: MockResult {
    public private(set) var result: T
    public func getResult() throws -> T? { result }

    public init(result: T) {
        self.result = result
    }
}

public struct MockFailure: MockResult {
    public private(set) var error: Error
    public func getResult() throws -> Never? { throw error }
    
    public init(error: Error) {
        self.error = error
    }
}

final public class MockNetworkClient: NetworkClient {
    public var fetchResult: (any MockResult)?
    private(set) public var fetchResultCalled = false
    
    public func fetch<T>(
        api: URLGenerator,
        request: T
    ) async throws -> T.ResponseDataType? where T: APIRequest {
        fetchResultCalled = true
        return try fetchResult?.getResult() as? T.ResponseDataType
    }
    
    public init() {}
}
