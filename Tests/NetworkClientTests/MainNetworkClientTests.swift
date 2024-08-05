//  Created by Steven Curtis

@testable import NetworkClient
import XCTest

final class MainNetworkClientTests: XCTestCase {
    private var mainNetworkClient: MainNetworkClient!
    private var mockErrorHandler: MockErrorHandler!
    private var mockDataParser: MockDataParser!
    
    override func setUp() {
        super.setUp()
        mockErrorHandler = MockErrorHandler(shouldThrowError: false)
        mockDataParser = MockDataParser()
        
        let urlConfiguration = URLSessionConfiguration.ephemeral
        urlConfiguration.protocolClasses = [MockURLProtocol.self]
        let mockSession = URLSession(configuration: urlConfiguration)
        
        let configuration = NetworkClientConfiguration.make(
            urlSession: mockSession,
            errorHandler: mockErrorHandler,
            dataParser: mockDataParser
        )
        
        mainNetworkClient = MainNetworkClient(configuration: configuration)
    }
    
    override func tearDown() {
        mainNetworkClient = nil
        mockErrorHandler = nil
        mockDataParser = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    func testFetch_whenResponseIs200_callsHandleResponseAndHandleStatusCode() async throws {
        let mockJSONData = try XCTUnwrap(
            "{\"message\":\"testdata\"}".data(
                using: .utf8
            )
        )
        setupMockResponse(statusCode: 200, data: mockJSONData)
        let mockRequest = MockRequest()
        let mockAPI = MockAPI.get
        _ = try await mainNetworkClient.fetch(
            api: mockAPI,
            request: mockRequest
        )
        
        XCTAssertEqual(mockErrorHandler.handleResponseCallCount, 1)
        XCTAssertEqual(mockErrorHandler.handleStatusCodeCallCount, 1)
    }
    
    func testFetch_whenResponseIs200_callsParseData() async throws {
        let mockJSONData = try XCTUnwrap(
            "{\"message\":\"testdata\"}".data(
                using: .utf8
            )
        )
        setupMockResponse(statusCode: 200, data: mockJSONData)
        let mockRequest = MockRequest()
        let mockAPI = MockAPI.get
        _ = try await mainNetworkClient.fetch(
            api: mockAPI,
            request: mockRequest
        )
        
        XCTAssertEqual(mockDataParser.parseDataCallCount, 1)
    }
    
    func testFetch_whenResponseIs204_doesNotCallParseData() async throws {
        let mockJSONData = try XCTUnwrap(
            "{\"message\":\"testdata\"}".data(
                using: .utf8
            )
        )
        setupMockResponse(statusCode: 204, data: mockJSONData)
        let mockRequest = MockRequest()
        let mockAPI = MockAPI.get
        _ = try await mainNetworkClient.fetch(
            api: mockAPI,
            request: mockRequest
        )
        
        XCTAssertEqual(mockDataParser.parseDataCallCount, 0)
    }
    
    func testFetch_whenResponseIs200_callsHandleResponseAndHandleStatusCode() throws {
        let expectation = expectation(description: "Completion handler invoked")
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(statusCode: 200, data: mockJSONData)
        let mockRequest = MockRequest()
        let mockAPI = MockAPI.get

        mainNetworkClient.fetch(api: mockAPI, request: mockRequest, completionQueue: .main) { [weak self] response in
            switch response {
            case .success:
                XCTAssertEqual(self?.mockErrorHandler.handleResponseCallCount, 1)
                XCTAssertEqual(self?.mockErrorHandler.handleStatusCodeCallCount, 1)
            case .failure:
                XCTFail("Expected success response")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetch_whenResponseIs200_callsParseData() throws {
        let expectation = expectation(description: "Completion handler invoked")
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(statusCode: 200, data: mockJSONData)
        let mockRequest = MockRequest()
        let mockAPI = MockAPI.get

        mainNetworkClient.fetch(api: mockAPI, request: mockRequest, completionQueue: .main) { [weak self] response in
            switch response {
            case .success:
                XCTAssertEqual(self?.mockDataParser.parseDataCallCount, 1)
            case .failure:
                XCTFail("Expected success response")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFetch_whenResponseIs204_doesNotCallParseData() throws {
        let expectation = expectation(description: "Completion handler invoked")
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(statusCode: 204, data: mockJSONData)
        let mockRequest = MockRequest()
        let mockAPI = MockAPI.get

        mainNetworkClient.fetch(api: mockAPI, request: mockRequest, completionQueue: .main) { [weak self] response in
            switch response {
            case .success:
                XCTAssertEqual(self?.mockDataParser.parseDataCallCount, 0)
            case .failure:
                XCTFail("Expected success response")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

extension MainNetworkClientTests {
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
