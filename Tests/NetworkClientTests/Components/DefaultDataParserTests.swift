//  Created by Steven Curtis

@testable import NetworkClient
import XCTest

final class DefaultDataParserTests: XCTestCase {
    private var dataParser: DataParser!

    override func setUp() {
        super.setUp()
        dataParser = DefaultDataParser.make()
    }

    override func tearDown() {
        dataParser = nil
        super.tearDown()
    }

    func testParseValidData() throws {
        let validJSONString = "{\"message\":\"Hello, World!\"}"
        let data = try XCTUnwrap(validJSONString.data(using: .utf8))
        let mockRequest = MockRequest()
        
        do {
            let parsedData = try dataParser.parseData(data, for: mockRequest)
            XCTAssertEqual(parsedData, MockDto(message: "Hello, World!"))
        } catch {
            XCTFail("Parsing failed with error: \(error)")
        }
    }

    func testParseInvalidData() {
        let invalidData = Data([0x01, 0x02, 0x03])
        let mockRequest = MockRequest()
        XCTAssertThrowsError(try dataParser.parseData(invalidData, for: mockRequest)) { error in
            XCTAssertEqual(
                error as? APIError,
                APIError.parseResponse(
                    errorMessage: "The data couldn’t be read because it isn’t in the correct format."
                )
            )
        }
    }
}
