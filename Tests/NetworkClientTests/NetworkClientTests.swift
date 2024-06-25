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
            api: MockAPI.get,
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
        let mockAPI = MockAPI.post(body: .encodable(String()))
        networkClient.fetch(
            api: mockAPI,
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
        let mockAPI = MockAPI.put

        let expected = MockDto(message: "success")
        networkClient.fetch(
            api: mockAPI,
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
        let mockAPI = MockAPI.delete
        networkClient.fetch(
            api: mockAPI,
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
        let mockAPI = MockAPI.delete
        networkClient.fetch(
            api: mockAPI,
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
        let mockAPI = MockAPI.patch(body: .encodable(String()))
        networkClient.fetch(
            api: mockAPI,
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
        let mockAPI = MockAPI.get
        let expectation = expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: mockAPI, request: request, completionQueue: queue) { response in
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
        let mockAPI = MockAPI.get
        let expectation = expectation(description: "NetworkClient fetch expectation")
        networkClient.fetch(api: mockAPI, request: request, completionQueue: queue) { response in
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
        let mockAPI = MockAPI.get
        networkClient.fetch(
            api: mockAPI,
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
        let mockAPI = MockAPI.get
        networkClient.fetch(
            api: mockAPI,
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
        let mockAPI = MockAPI.get
        networkClient.fetch(
            api: mockAPI,
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
        let mockAPI = MockAPI.get
        networkClient.fetch(
            api: mockAPI,
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
        let mockAPI = MockAPI.get
        let expected = MockDto(message: "testdata")
        setupMockResponse(statusCode: 200, data: mockJSONData)

        let data = try? await networkClient.fetch(
            api: mockAPI,
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchPostAsync_successfulDataFetch() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        let expected = MockDto(message: "success")
        let mockAPI = MockAPI.post(body: .encodable(String()))
        setupMockResponse(statusCode: 200, data: mockJSONData)

        let data = try? await networkClient.fetch(
            api: mockAPI,
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchPutAsync_successfulDataFetch() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        let expected = MockDto(message: "success")
        let mockAPI = MockAPI.put
        setupMockResponse(statusCode: 200, data: mockJSONData)

        let data = try? await networkClient.fetch(
            api: mockAPI,
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchPatchAsync_successfulDataFetch() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        let expected = MockDto(message: "success")
        setupMockResponse(statusCode: 200, data: mockJSONData)
        let mockAPI = MockAPI.patch(body: .encodable(String()))

        let data = try? await networkClient.fetch(
            api: mockAPI,
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchDeleteAsync_successfulDataFetch() async throws {
        setupMockResponse(statusCode: 204)
        let mockAPI = MockAPI.delete
        let data = try? await networkClient.fetch(
            api: mockAPI,
            request: request
        )
        XCTAssertEqual(data, nil)
    }
    
    func testFetchDeleteAsyncNoRequest_successfulDataFetch() async throws {
        setupMockResponse(statusCode: 204)
        let mockAPI = MockAPI.delete
        let data = try? await networkClient.fetch(
            api: mockAPI
        )
        XCTAssertEqual(data, nil)
    }

    func testFetchGetAsync_handlesInvalidData() async throws {
        let mockJSONData = try XCTUnwrap("{\"notamessage\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(data: mockJSONData)
        let mockAPI = MockAPI.get

        do {
            _ = try await networkClient.fetch(
                api: mockAPI,
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
        let mockAPI = MockAPI.get
        do {
            _ = try await networkClient.fetch(
                api: mockAPI,
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
        let mockAPI = MockAPI.get
        do {
            _ = try await networkClient.fetch(
                api: mockAPI,
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
        let mockAPI = MockAPI.get
        do {
            _ = try await networkClient.fetch(
                api: mockAPI,
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
        let mockAPI = MockAPI.get
        do {
            _ = try await networkClient.fetch(
                api: mockAPI,
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
        let mockAPI = MockAPI.get
        do {
            _ = try await networkClient.fetch(
                api: mockAPI,
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
        let mockAPI = MockAPI.get
        do {
            _ = try await networkClient.fetch(
                api: mockAPI,
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
