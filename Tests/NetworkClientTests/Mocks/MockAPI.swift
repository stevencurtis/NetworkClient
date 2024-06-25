//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

enum MockAPI: URLGenerator {
    case delete
    case get
    case patch(body: HTTPBody)
    case post(body: HTTPBody)
    case put

    var method: HTTPMethod {
        switch self {
        case .delete:
            return .delete()
        case .get:
            return .get()
        case .patch(body: let body):
            return .patch(body: body)
        case .post(body: let body):
            return .post(body: body)
        case .put:
            return .put()
        }
    }
    
    var url: URL? {
        var component = URLComponents()
        component.scheme = "https"
        component.host = "endpoint"
        component.path = "/path/"
        return component.url
    }
}
