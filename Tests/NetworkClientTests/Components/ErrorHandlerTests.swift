//  Created by Steven Curtis

@testable import NetworkClient
import XCTest

final class ErrorHandlerTests: XCTestCase {
    private var errorHandler: ErrorHandlerProtocol!

    override func setUp() {
        super.setUp()
        errorHandler = ErrorHandler.make()
    }

    override func tearDown() {
        errorHandler = nil
        super.tearDown()
    }

    func testHandleStatusCodeSuccess() {
        XCTAssertNoThrow(try errorHandler.handleStatusCode(statusCode: 200))
        XCTAssertNoThrow(try errorHandler.handleStatusCode(statusCode: 299))
    }

    func testHandleStatusCodeBadRequest() {
        XCTAssertThrowsError(try errorHandler.handleStatusCode(statusCode: 400)) { error in
            XCTAssertEqual(error as? APIError, APIError.httpError(.badRequest))
        }
    }

    func testHandleStatusCodeUnauthorized() {
        XCTAssertThrowsError(try errorHandler.handleStatusCode(statusCode: 401)) { error in
            XCTAssertEqual(error as? APIError, APIError.httpError(.unauthorized))
        }
    }

    func testHandleStatusCodeForbidden() {
        XCTAssertThrowsError(try errorHandler.handleStatusCode(statusCode: 403)) { error in
            XCTAssertEqual(error as? APIError, APIError.httpError(.forbidden))
        }
    }

    func testHandleStatusCodeNotFound() {
        XCTAssertThrowsError(try errorHandler.handleStatusCode(statusCode: 404)) { error in
            XCTAssertEqual(error as? APIError, APIError.httpError(.notFound))
        }
    }

    func testHandleStatusCodeServerError() {
        XCTAssertThrowsError(try errorHandler.handleStatusCode(statusCode: 500)) { error in
            XCTAssertEqual(error as? APIError, APIError.httpError(.serverError))
        }
    }

    func testHandleStatusCodeUnknown() {
        XCTAssertThrowsError(try errorHandler.handleStatusCode(statusCode: 600)) { error in
            XCTAssertEqual(error as? APIError, APIError.httpError(.unknown))
        }
    }
    
    func testHandleResponseValid() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let validResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let data = Data()

        XCTAssertNoThrow(try errorHandler.handleResponse(data, validResponse))
    }

    func testHandleResponseInvalid() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let invalidResponse = URLResponse(
            url: url,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        let data = Data()

        XCTAssertThrowsError(try errorHandler.handleResponse(data, invalidResponse)) { error in
            XCTAssertEqual(error as? APIError, APIError.invalidResponse(data, invalidResponse))
        }
    }
}
