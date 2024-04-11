@testable import NetworkClient
import XCTest

final class NetworkClientTests: XCTestCase {
    private let request = MockRequest()
    private let queue = DispatchQueue(label: "NetworkClientTests")
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.reset()
        super.tearDown()
    }
    
    func testFetchGet_successfullyParsesExpectedJSONData() throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(statusCode: 200, data: mockJSONData)
        let expectation = expectation(description: "NetworkClient fetch expectation")

        let expected = MockDto(message: "testdata")
        let networkClient = makeSUT(session: session)
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
    
    func testFetchGetForbidden_tokenUpdated() throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(statusCodeSequence: [
            (403, mockJSONData),
            (200, mockJSONData)
        ])
        let expectation = expectation(description: "NetworkClient fetch expectation")

        let tokenManager = MockSyncTokenManager()
        let networkClient = makeSUT(session: session, syncTokenManager: tokenManager)
        networkClient.fetch(
            api: MockAPI.endpoint,
            method: .get(headers: [:], token: nil),
            request: request,
            completionQueue: queue
        ) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure:
                expectation.fulfill()
                break
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(tokenManager.requestBodyDataCalled)
        XCTAssertTrue(tokenManager.updateTokenDataCalled)
    }
    
    func testFetchPost_handlesSuccessResponse() throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        setupMockResponse(statusCode: 201, data: mockJSONData)
        let expectation = expectation(description: "NetworkClient fetch expectation")

        let expected = MockDto(message: "success")
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
        setupMockResponse(statusCode: 999)

        let expectation = expectation(description: "NetworkClient fetch expectation")
        let networkClient = makeSUT(session: session)
        networkClient.fetch(api: MockAPI.endpoint, method: .get(), request: request, completionQueue: queue) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.unknown))
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchGet_handlesBadRequestError() throws {
        setupMockResponse(statusCode: 400)

        let expectation = expectation(description: "NetworkClient fetch expectation")
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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

    func testFetchGet_handlesNotFoundError() throws {
        setupMockResponse(statusCode: 404)

        let expectation = expectation(description: "NetworkClient fetch expectation")
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .get(),
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchGetAsyncForbidden_tokenUpdated() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(statusCodeSequence: [
            (403, mockJSONData),
            (200, mockJSONData)
        ])
        
        let tokenManager = MockTokenManager()
        let networkClient = makeSUT(session: session, tokenManager: tokenManager)

        let _ = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .get(),
            request: request
        )
        XCTAssertTrue(tokenManager.requestBodyDataCalled)
        XCTAssertTrue(tokenManager.updateTokenCalled)
    }
    
    func testFetchPostAsync_successfulDataFetch() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"success\"}".data(using: .utf8))
        let expected = MockDto(message: "success")
        setupMockResponse(statusCode: 200, data: mockJSONData)
        let networkClient = makeSUT(session: session)

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
        let networkClient = makeSUT(session: session)

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
        let networkClient = makeSUT(session: session)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .patch(),
            request: request
        )
        XCTAssertEqual(data, expected)
    }
    
    func testFetchDeleteAsync_successfulDataFetch() async throws {
        setupMockResponse(statusCode: 204)
        let networkClient = makeSUT(session: session)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .delete(),
            request: request
        )
        XCTAssertEqual(data, nil)
    }
    
    func testFetchDeleteAsyncNoRequest_successfulDataFetch() async throws {
        setupMockResponse(statusCode: 204)
        let networkClient = makeSUT(session: session)

        let data = try? await networkClient.fetch(
            api: MockAPI.endpoint,
            method: .delete()
        )
        XCTAssertEqual(data, nil)
    }

    func testFetchGetAsync_handlesInvalidData() async throws {
        let mockJSONData = try XCTUnwrap("{\"notamessage\":\"testdata\"}".data(using: .utf8))
        setupMockResponse(statusCode: 999, data: mockJSONData)
        let networkClient = makeSUT(session: session)

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
            XCTAssertEqual(apiError, .httpError(.unknown))
        }
    }

    func testFetchGetAsync_handlesBadRequestError() async throws {
        setupMockResponse(statusCode: 400)
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
        let networkClient = makeSUT(session: session)
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
    private func makeSUT(
        session: URLSession,
        tokenManager: TokenProvider? = nil,
        syncTokenManager: SyncTokenProvider? = nil
    ) -> NetworkClient {
        MainNetworkClient(
            urlSession: session,
            tokenManager: tokenManager,
            syncTokenManager: syncTokenManager
        )
    }
}

extension NetworkClientTests {
    func setupMockResponse(statusCodeSequence: [(Int, Data?)]) {
        MockURLProtocol.responseSequence = statusCodeSequence
    }
    
    private func setupMockResponse(
        statusCode: Int,
        data: Data = Data()
    ) {
            MockURLProtocol.responseSequence = [(statusCode, data)]
    }
}
