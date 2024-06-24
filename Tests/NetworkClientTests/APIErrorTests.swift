@testable import NetworkClient
import XCTest

final class APIErrorTests: XCTestCase {
    func testNetworkError() {
         let error = APIError.network(errorMessage: "Connection failed")
         XCTAssertEqual(error.errorDescription, "Connection failed")
     }

     func testNoDataError() {
         let error = APIError.noData
         XCTAssertEqual(error.errorDescription, "No data")
     }

     func testParseResponseError() {
         let error = APIError.parseResponse(errorMessage: "Invalid JSON")
         XCTAssertEqual(error.errorDescription, "Invalid JSON")
     }

     func testRequestError() {
         let error = APIError.request
         XCTAssertEqual(error.errorDescription, "Could not process request")
     }

     func testHttpError() {
         let httpError = HTTPError.serverError
         let error = APIError.httpError(httpError)
         XCTAssertEqual(error.errorDescription, httpError.localizedDescription)
     }

     func testInvalidResponseError() {
         let data = Data("some data".utf8)
         let response = HTTPURLResponse(url: URL(string: "http://example.com")!,
                                        statusCode: 400,
                                        httpVersion: nil,
                                        headerFields: nil)
         let error = APIError.invalidResponse(data, response)
         XCTAssertEqual(error.errorDescription, "Invalid response")
     }

     func testBearerTokenError() {
         let error = APIError.bearerToken
         XCTAssertEqual(error.errorDescription, "Bearer token error")
     }

     func testUnknownError() {
         let error = APIError.unknown
         XCTAssertEqual(error.errorDescription, "Unknown Error")
     }
}
