//  Created by Steven Curtis

@testable import NetworkClient
import XCTest

final class HTTPErrorTests: XCTestCase {
    func testBadRequestErrorDescription() {
        let error = HTTPError.badRequest
        XCTAssertEqual(error.errorDescription, "Bad Request")
    }

    func testUnauthorizedErrorDescription() {
        let error = HTTPError.unauthorized
        XCTAssertEqual(error.errorDescription, "Unauthorized")
    }

    func testForbiddenErrorDescription() {
        let error = HTTPError.forbidden
        XCTAssertEqual(error.errorDescription, "Forbidden")
    }

    func testNotFoundErrorDescription() {
        let error = HTTPError.notFound
        XCTAssertEqual(error.errorDescription, "Not Found")
    }

    func testServerErrorDescription() {
        let error = HTTPError.serverError
        XCTAssertEqual(error.errorDescription, "Internal Server Error")
    }

    func testUnknownErrorDescription() {
        let error = HTTPError.unknown
        XCTAssertEqual(error.errorDescription, "Unknown HTTP Error")
    }
}
