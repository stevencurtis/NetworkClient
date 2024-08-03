//  Created by Steven Curtis

import Foundation

public enum TokenType {
    case bearer(token: () -> String?)
    case queryParameter(token: String)
    case requestBody(token: String)
    case customHeader(headerName: String, token: String)
}
