import XCTest
@testable import NetworkClient

final class DictionaryExtensionTests: XCTestCase {
    func testExtension() throws {
        let data : [String : Any]? = ["email": "eve.holt@reqres.in", "password": "cityslicka"]
        let stringParams = try XCTUnwrap(data?.parameters())
        let straightData =
        try XCTUnwrap("email=eve.holt@reqres.in&password=cityslicka".data(using: .utf8))
        let dataParams = try XCTUnwrap(stringParams.data(using: String.Encoding.utf8, allowLossyConversion: false))
        XCTAssertEqual(dataParams.count, straightData.count)
    }
}
