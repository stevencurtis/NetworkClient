import XCTest
@testable import NetworkClient

final class NetworkClientTests: XCTestCase {
    private var networkClient: NetworkClient!
    private let request = MockRequest()

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)
        networkClient = MainNetworkClient(urlSession: urlSession)
    }
    
    func testNetworkClientSuccess() {
        let expectation = XCTestExpectation(description: "response")
        
        let mockJSONData = "{\"message\":\"testdata\"}".data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://endpoint/path/")
            return (HTTPURLResponse(), mockJSONData)
        }

        let expected: MockDto = .init(message: "testdata")
        networkClient.request(api: MockApi.endpoint, method: .get(), request: request) { response in
            switch response {
            case .success(let list):
                XCTAssertEqual(list, expected)
                expectation.fulfill()
            case .failure:
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 1)
    }
    
    func testNetworkClientFailure() {
        let expectation = XCTestExpectation(description: "response")
        
        let mockJSONData = "".data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://endpoint/path/")
            return (HTTPURLResponse(), mockJSONData)
        }
        
        networkClient.request(api: MockApi.endpoint, method: .get(), request: request) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .parseResponse)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1)
    }
    
    func testNetworkClientAsyncSuccess() async {
        let mockJSONData = "{\"message\":\"testdata\"}".data(using: .utf8)!
        let expected: MockDto = .init(message: "testdata")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://endpoint/path/")
            return (HTTPURLResponse(), mockJSONData)
        }
        
        let data = try? await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        XCTAssertEqual(data, expected)
    }
    
    func testNetworkClientAsyncFailure() async {
        let mockJSONData = "".data(using: .utf8)!
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://endpoint/path/")
            return (HTTPURLResponse(), mockJSONData)
        }
        do {
            _ = try await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        } catch let error {
            XCTAssertNotNil(error)
        }
    }
}
