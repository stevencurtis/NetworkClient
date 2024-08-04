//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

struct MockAPIRequest: APIRequest {
    typealias ResponseDataType = String

    func make(api: URLGenerator) throws -> URLRequest {
        guard let url = api.url else { throw APIError.unknown }
        var request = URLRequest(url: url)
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["key": "value"],
            options: []
        )
        return request
    }

    func parseResponse(data: Data) throws -> String {
        return String(data: data, encoding: .utf8) ?? ""
    }
}
