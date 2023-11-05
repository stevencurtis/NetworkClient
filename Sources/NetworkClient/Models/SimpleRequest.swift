import Foundation

struct SimpleRequest<T: Decodable>: APIRequest {
    typealias ResponseDataType = T
    func parseResponse(data: Data) throws -> ResponseDataType {
        let decoder = JSONDecoder()
        return try decoder.decode(ResponseDataType.self, from: data)
    }
}
