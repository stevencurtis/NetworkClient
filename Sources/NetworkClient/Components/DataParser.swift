//  Created by Steven Curtis

import Foundation

public protocol DataParser {
    func parseData<T: APIRequest>(_ data: Data, for request: T) throws -> T.ResponseDataType
}

public struct DefaultDataParser: DataParser {
    public func parseData<T: APIRequest>(_ data: Data, for request: T) throws -> T.ResponseDataType {
        try request.parseResponse(data: data)
    }
    
    public static func make() -> DataParser {
        DefaultDataParser()
    }
}
