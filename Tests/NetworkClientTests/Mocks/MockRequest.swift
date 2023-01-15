//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

struct MockRequest: APIRequest {
    func parseResponse(data: Data) throws -> MockDto {
        let decoder = JSONDecoder()
        return try decoder.decode(MockDto.self, from: data)
    }
}

struct MockDto: Decodable, Equatable {
    let message: String
}
