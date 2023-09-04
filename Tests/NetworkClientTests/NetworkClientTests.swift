import XCTest
@testable import NetworkClient

final class NetworkClientTests: XCTestCase {
    private var networkClient: NetworkClient!
    private let request = MockRequest()

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)
        networkClient = MainNetworkClient(urlSession: urlSession)
    }
    
    override func tearDown() {
        networkClient = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    func testNetworkClientSuccess() throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://endpoint/path/")
            return (HTTPURLResponse(), mockJSONData)
        }

        let expected: MockDto = .init(message: "testdata")
        networkClient.request(api: MockApi.endpoint, method: .get(), request: request) { response in
            switch response {
            case .success(let list):
                XCTAssertEqual(list, expected)
            case .failure:
                XCTFail()
            }
        }
    }
    
    func testNetworkClientParseResponseFailure() throws {
        MockURLProtocol.requestHandler = { request in
            return (HTTPURLResponse(), Data())
        }
        
        networkClient.request(api: MockApi.endpoint, method: .get(), request: request) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .parseResponse(errorMessage: "The data couldn’t be read because it isn’t in the correct format."))
            }
        }
    }
    
    func testNetworkClientBadRequestFailure() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
            return (response, mockJSONData)
        }

        networkClient.request(api: MockApi.endpoint, method: .get(), request: request) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.badRequest))
            }
        }
    }
    
    func testNetworkClientUnauthorizedFailure() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            return (response, Data())
        }

        networkClient.request(api: MockApi.endpoint, method: .get(), request: request) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.unauthorized))
            }
        }
    }
    
    func testNetworkClientForbiddenFailure() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            return (response, Data())
        }
        
        networkClient.request(api: MockApi.endpoint, method: .get(), request: request) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.forbidden))
            }
        }
    }
    
    func testNetworkClientNotFoundFailure() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            return (response, Data())
        }

        networkClient.request(api: MockApi.endpoint, method: .get(), request: request) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.notFound))
            }
        }
    }
    
    func testNetworkClientServerErrorFailure() throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            return (response, Data())
        }

        networkClient.request(api: MockApi.endpoint, method: .get(), request: request) { response in
            switch response {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, .httpError(.serverError))
            }
        }
    }
    
    func testNetworkClientAsyncSuccess() async throws {
        let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
        let expected: MockDto = .init(message: "testdata")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, MockApi.endpoint.url?.absoluteString)
            return (HTTPURLResponse(), mockJSONData)
        }

        let data = try? await networkClient.fetch(api: MockApi.endpoint, method: .get(), request: request)
        XCTAssertEqual(data, expected)
    }

    func testNetworkClientAsyncFailure() async throws {
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
    
    func testNetworkClientAsyncFailureBadRequest() async throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
            return (response, mockJSONData)
        }
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
    
    func testNetworkClientAsyncFailureUnauthorized() async throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
            return (response, mockJSONData)
        }
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
    
    func testNetworkClientAsyncFailureForbidden() async throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
            return (response, mockJSONData)
        }
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
    
    func testNetworkClientAsyncFailureNotFound() async throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
            return (response, mockJSONData)
        }
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
    
    func testNetworkClientAsyncFailureServerError() async throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
            return (response, mockJSONData)
        }
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
    
    func testNetworkClientAsyncFailureUnknown() async throws {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: 600, httpVersion: nil, headerFields: [:]) else {
                XCTFail("Failed to create HTTPURLResponse")
                return (HTTPURLResponse(), Data())
            }
            let mockJSONData = try XCTUnwrap("{\"message\":\"testdata\"}".data(using: .utf8))
            return (response, mockJSONData)
        }
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
