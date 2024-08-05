//  Created by Steven Curtis

@testable import NetworkClient
import XCTest

final class BasicRequestTests: XCTestCase {
    func testSuccessfulParse() throws {
            let json = """
            {
                "id": 1,
                "name": "Test Name"
            }
            """
            let data = Data(json.utf8)
            let request = BasicRequest<TestModel>()
            
            do {
                let model = try request.parseResponse(data: data)
                XCTAssertEqual(model.id, 1)
                XCTAssertEqual(model.name, "Test Name")
            } catch {
                XCTFail("Parsing failed when it should have succeeded: \(error)")
            }
        }

        func testFailedParse() throws {
            let json = """
            {
                "invalid_field": "value"
            }
            """
            let data = Data(json.utf8)
            let request = BasicRequest<TestModel>()
            
            XCTAssertThrowsError(try request.parseResponse(data: data)) { error in
                XCTAssertTrue(error is DecodingError)
            }
        }
}
