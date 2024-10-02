//  Created by Steven Curtis

import Foundation

public struct NetworkClientConfiguration {
    public enum URLRequestCreatorConfiguration {
        case basic(token: TokenType?, headers: [String: String] = [:])
        case custom(handler: URLRequestHandler)
    }
    let urlSession: URLSession
    let errorHandler: ErrorHandlerProtocol
    let dataParser: DataParser
    let urlRequestCreator: URLRequestCreator

    private init(
        urlSession: URLSession,
        errorHandler: ErrorHandlerProtocol,
        dataParser: DataParser,
        urlRequestCreator: URLRequestCreator
    ) {
        self.urlSession = urlSession
        self.errorHandler = errorHandler
        self.dataParser = dataParser
        self.urlRequestCreator = urlRequestCreator
    }
    
    public static func make(
        urlSession: URLSession = .shared,
        errorHandler: ErrorHandlerProtocol = ErrorHandler.make(),
        dataParser: DataParser = DefaultDataParser.make(),
        requestCreatorConfiguration: URLRequestCreatorConfiguration = .basic(
            token: nil,
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
        )
    ) -> NetworkClientConfiguration {
        let requestCreator: URLRequestCreator = {
            switch requestCreatorConfiguration {
            case .basic(let token, let headers):
                return URLRequestHandler(headers: headers, token: token)
            case .custom(let handler):
                return handler
            }
        }()
        return NetworkClientConfiguration(
            urlSession: urlSession,
            errorHandler: errorHandler,
            dataParser: dataParser,
            urlRequestCreator: requestCreator
        )
    }
}
