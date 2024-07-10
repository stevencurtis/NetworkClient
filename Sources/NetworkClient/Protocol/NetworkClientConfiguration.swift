//  Created by Steven Curtis

public struct NetworkClientConfiguration {
    let headers: [String: String]
    
    public init() {
        headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}
