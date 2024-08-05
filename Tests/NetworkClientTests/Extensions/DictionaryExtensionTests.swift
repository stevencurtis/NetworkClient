//  Created by Steven Curtis

@testable import NetworkClient
import XCTest

final class DictionaryExtensionTests: XCTestCase {
    func testParameters_unsupportedType() {
        let dictionary: [String: Any] = ["data": Data()]
        let result = dictionary.parameters()
        XCTAssertEqual(result, "")
    }

    func testParameters_emptyDictionary() {
        let dictionary: [String: Any] = [:]
        let result = dictionary.parameters()
        XCTAssertEqual(result, "")
    }
    
    func testParameters_supportedTypes() {
        let dictionary: [String: Any] = ["name": "John", "age": 3, "test score": 3.4]
        let result = dictionary.parameters()
        let expectedComponents = ["age=3", "name=John", "test%20score=3.4"]
        let resultComponents = result.split(separator: "&").map(String.init)
        XCTAssertEqual(Set(resultComponents), Set(expectedComponents))
    }
}
