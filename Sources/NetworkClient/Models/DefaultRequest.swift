//  Created by Steven Curtis

public struct DefaultRequest: APIRequest {
    public let body: HTTPBody?
    
    public init(body: HTTPBody? = nil) {
        self.body = body
    }
}
