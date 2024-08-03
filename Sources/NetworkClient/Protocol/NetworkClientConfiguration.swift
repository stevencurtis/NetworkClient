//  Created by Steven Curtis

import Foundation

public struct NetworkClientConfiguration {
    let headers: [String: String]
    let urlSession: URLSession
    let token: TokenType?
    let errorHandler: ErrorHandlerProtocol
    let dataParser: DataParser
    let urlRequestCreator: URLRequestCreator

    private init(
        headers: [String: String],
        urlSession: URLSession,
        token: TokenType?,
        errorHandler: ErrorHandlerProtocol,
        dataParser: DataParser,
        urlRequestCreator: URLRequestCreator
    ) {
        self.headers = headers
        self.urlSession = urlSession
        self.token = token
        self.errorHandler = errorHandler
        self.dataParser = dataParser
        self.urlRequestCreator = urlRequestCreator
    }
    
    public static func make(
        headers: [String: String] = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ],
        urlSession: URLSession = .shared,
        token: TokenType? = nil,
        errorHandler: ErrorHandlerProtocol = ErrorHandler.make(),
        dataParser: DataParser = DefaultDataParser.make()
        
    ) -> NetworkClientConfiguration {
        NetworkClientConfiguration(
            headers: headers,
            urlSession: urlSession,
            token: token,
            errorHandler: errorHandler,
            dataParser: dataParser,
            urlRequestCreator: URLRequestHandler(
                headers: headers,
                token: token
            ))
    }
}
