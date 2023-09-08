import XCTest
@testable import NetworkClient

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
    
    func testFetch_successfullyParsesExpectedJSONData() throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://endpoint/path/")
            return (HTTPURLResponse(), mockJSONData)
        }
        let expectation = self.expectation(description: "NetworkClient fetch expectation")

        let expected: MockDto = .init(message: "testdata")
        networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request, completionQueue: queue) { response in
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
    
    func testFetch_handlesInvalidResponseData() throws {
        MockURLProtocol.requestHandler = { request in
            return (HTTPURLResponse(), Data())
        }
        let expectation = self.expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request, completionQueue: queue) { response in
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

    func testFetch_handlesBadRequestError() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
            return (response, mockJSONData)
        }

        let expectation = self.expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request, completionQueue: queue) { response in
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

    func testFetch_handlesUnauthorizedError() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            return (response, Data())
        }

        let expectation = self.expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request, completionQueue: queue) { response in
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

    func testFetch_handlesForbiddenError() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            return (response, Data())
        }

        let expectation = self.expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request, completionQueue: queue) { response in
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

    func testFetch_handlesNotFoundError() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            return (response, Data())
        }

        let expectation = self.expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request, completionQueue: queue) { response in
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

    func testFetch_handlesServerError() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            return (response, Data())
        }

        let expectation = self.expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request, completionQueue: queue) { response in
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

    func testFetchAsync_successfulDataFetch() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        let expected: MockDto = .init(message: "testdata")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, MockApi.endpoint.url?.absoluteString)
            return (HTTPURLResponse(), mockJSONData)
        }

        let data = try? await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        XCTAssertEqual(data, expected)
    }

    func testFetchAsync_handlesInvalidData() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, MockApi.endpoint.url?.absoluteString)
            let mockJSONData = try XCTUnwrap("{\"notamessage\":\"testdata\"}".data(using: .utf8))
            return (HTTPURLResponse(), mockJSONData)
        }
        do {
            _ = try await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        } catch let error {
            guard let apiError = error as? ApiError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .parseResponse(errorMessage: "The data couldn’t be read because it is missing."))
        }
    }

    func testFetchAsync_handlesBadRequestError() async throws {
        setupMockResponse(statusCode: 400)
        do {
            _ = try await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        } catch let error {
            guard let apiError  = error as? ApiError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.badRequest))
        }
    }

    func testFetchAsync_handlesUnauthorizedError() async throws {
        setupMockResponse(statusCode: 401)
        do {
            _ = try await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        } catch let error {
            guard let apiError  = error as? ApiError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.unauthorized))
        }
    }

    func testFetchAsync_handlesForbiddenError() async throws {
        setupMockResponse(statusCode: 403)
        do {
            _ = try await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        } catch let error {
            guard let apiError  = error as? ApiError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.forbidden))
        }
    }

    func testFetchAsync_handlesNotFoundError() async throws {
        setupMockResponse(statusCode: 404)
        do {
            _ = try await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        } catch let error {
            guard let apiError  = error as? ApiError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.notFound))
        }
    }

    func testFetchAsync_handlesServerError() async throws {
        setupMockResponse(statusCode: 500)
        do {
            _ = try await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        } catch let error {
            guard let apiError  = error as? ApiError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.serverError))
        }
    }

    func testFetchAsync_handlesUnknownError() async throws {
        setupMockResponse(statusCode: 600)
        do {
            _ = try await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        } catch let error {
            guard let apiError  = error as? ApiError else {
                XCTFail()
                return
            }
            XCTAssertEqual(apiError, .httpError(.unknown))
        }
    }
}

extension NetworkClientTests {
    private func setupMockResponse(statusCode: Int, data: Data = Data()) {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            return (response, data)
        }
    }
}
