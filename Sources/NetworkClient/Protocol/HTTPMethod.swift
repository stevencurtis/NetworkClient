//  Created by Steven Curtis

public enum HTTPMethod {
    case get(headers: [String : String] = [:], token: String? = nil)
    case post(headers: [String : String] = [:], token: String? = nil, body: [String: Any])
    case put(headers: [String : String] = [:], token: String? = nil)
    case delete(headers: [String : String] = [:], token: String? = nil)
    case patch(headers: [String : String] = [:], token: String? = nil)
}

extension HTTPMethod: CustomStringConvertible {
    public var operation: String {
        return self.description
    }
    
    public var description: String {
        switch self {
            case .get:
                return "GET"
            case .post:
                return "POST"
            case .put:
                return "PUT"
            case .delete:
                return "DELETE"
            case .patch:
                return "PATCH"
        }
    }
    
    func getHeaders() -> [String: String]? {
        switch self {
        case .get(headers: let headers, _):
            return headers
        case .post(headers: let headers, _, body: _):
            return headers
        case .put(headers: let headers, _):
            return headers
        case .delete(headers: let headers, _):
            return headers
        case .patch(headers: let headers, _):
            return headers
        }
    }
    
    func getToken() -> String? {
        switch self {
        case .get(_, token: let token):
            return token
        case .post(_, token: let token, body: _):
            return token
        case .put(_, token: let token):
            return token
        case .delete(_, token: let token):
            return token
        case .patch(_, token: let token):
            return token
        }
    }
    
    func getData() -> [String: Any]? {
        switch self {
        case .get:
            return nil
        case .post( _, _, body: let body):
            return body
        case .put:
            return nil
        case .delete:
            return nil
        case .patch:
            return nil
        }
    }
}

extension HTTPMethod {
    func with(token newToken: String) -> HTTPMethod {
        switch self {
        case .get(headers: let headers, _):
            return .get(headers: headers, token: newToken)
        case .post(headers: let headers, _, body: let body):
            return .post(headers: headers, token: newToken, body: body)
        case .put(headers: let headers, _):
            return .put(headers: headers, token: newToken)
        case .delete(headers: let headers, _):
            return .delete(headers: headers, token: newToken)
        case .patch(headers: let headers, _):
            return .patch(headers: headers, token: newToken)
        }
    }
}
