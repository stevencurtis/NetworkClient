//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

final class MockTokenManager: TokenProvider {
    private (set) var requestTokenCalled = false
    func requestToken() async throws -> String? {
        requestTokenCalled = true
        return nil
    }
    private (set) var requestRefreshTokenCalled = false
    func requestRefreshToken() async throws -> String? {
        requestRefreshTokenCalled = true
        return nil
    }
    private (set) var requestBodyDataCalled = false
    func requestBodyData() async throws -> [String : Any] {
        requestBodyDataCalled = true
        return [:]
    }
    private (set) var setDataCalled = false
    func setData(clientSecret: String, clientID: String, refreshToken: String?, token: String?) async {
        setDataCalled = true
    }
    private (set) var updateTokenCalled = false
    func updateToken(_ data: Data?) async {
        updateTokenCalled = true
    }
    
    var refreshTokenAPI: URLGenerator = MockAPI.endpoint
    
    var headers: [String : String] = [:]
    
}
