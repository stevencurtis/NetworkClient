//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

final class MockDataParser: DataParser {
    private(set) var parseDataCallCount = 0
    
    public func parseData<T: APIRequest>(_ data: Data, for request: T) throws -> T.ResponseDataType {
        parseDataCallCount += 1
        return try request.parseResponse(data: data)
    }
}
