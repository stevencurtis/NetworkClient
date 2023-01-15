//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

enum MockApi: URLGenerator {
    case endpoint
    
    var url: URL? {
        var component = URLComponents()
        component.scheme = "https"
        component.host = "endpoint"
        component.path = "/path/"
        return component.url
    }
}
