//  Created by Steven Curtis

import Foundation

public protocol URLGenerator {
    var url: URL? { get }
    var method: HTTPMethod { get }
}
