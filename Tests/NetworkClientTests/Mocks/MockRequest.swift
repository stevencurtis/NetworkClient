//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

struct MockRequest: APIRequest {
    func parseResponse(data: Data) throws -> MockDto? {
        let decoder = JSONDecoder()
        do {
            let dto = try decoder.decode(MockDto.self, from: data)
            return dto
        } catch let error {
            throw ApiError.parseResponse(errorMessage: error.localizedDescription)
        }
    }
}

struct MockDto: Decodable, Equatable {
    let message: String
}
