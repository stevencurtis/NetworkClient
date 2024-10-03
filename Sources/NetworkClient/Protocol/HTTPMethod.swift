//  Created by Steven Curtis

public enum HTTPBody {
    case json([String: Any])
    case encodable(Encodable)
}

public enum HTTPMethod {
    case get, post, put, delete, patch
}

extension HTTPMethod: CustomStringConvertible {
    public var operation: String {
        self.description
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
}
