//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

struct MockURLGenerator: URLGenerator {
    var method: HTTPMethod = .get
    var url: URL? = URL(string: "https://www.google.com")
}
