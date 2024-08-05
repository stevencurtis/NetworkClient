//  Created by Steven Curtis

import Foundation

public struct BasicRequest<T: Decodable>: APIRequest {
    public let body: HTTPBody?
    
    public typealias ResponseDataType = T
    public init(body: HTTPBody? = nil) { 
        self.body = body
    }
    public func parseResponse(data: Data) throws -> ResponseDataType {
        let decoder = JSONDecoder()
        return try decoder.decode(ResponseDataType.self, from: data)
    }
}
