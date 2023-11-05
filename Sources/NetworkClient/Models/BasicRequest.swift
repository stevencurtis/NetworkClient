import Foundation

public struct BasicRequest<T: Decodable>: APIRequest {
    public typealias ResponseDataType = T
    public func parseResponse(data: Data) throws -> ResponseDataType {
        let decoder = JSONDecoder()
        return try decoder.decode(ResponseDataType.self, from: data)
    }
}
