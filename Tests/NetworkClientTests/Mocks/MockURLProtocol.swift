//  Created by Steven Curtis

import Foundation
import XCTest

//final class MockURLProtocol: URLProtocol {
//    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
//
//    override class func canInit(with request: URLRequest) -> Bool {
//        true
//    }
//    
//    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
//        request
//    }
//    
//    override func startLoading() {
//        guard let handler = MockURLProtocol.requestHandler else {
//            XCTFail("Received unexpected request with no handler set")
//            return
//        }
//        do {
//            let (response, data) = try handler(request)
//            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
//            client?.urlProtocol(self, didLoad: data)
//            client?.urlProtocolDidFinishLoading(self)
//        } catch {
//            client?.urlProtocol(self, didFailWithError: error)
//        }
//    }
//    
//    override func stopLoading() { }
//}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data?))?
    static var responseSequence: [(statusCode: Int, data: Data?)] = []
    private static var callIndex = 0

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if MockURLProtocol.callIndex < MockURLProtocol.responseSequence.count {
            let responseInfo = MockURLProtocol.responseSequence[MockURLProtocol.callIndex]
            let response = HTTPURLResponse(url: self.request.url!, statusCode: responseInfo.statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = responseInfo.data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            MockURLProtocol.callIndex += 1
        } else {
            let response = HTTPURLResponse(url: self.request.url!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: nil)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
    
    static func reset() {
        MockURLProtocol.callIndex = 0
        MockURLProtocol.responseSequence = []
    }
}
