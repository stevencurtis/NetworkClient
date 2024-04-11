//  Created by Steven Curtis

import Foundation
@testable import NetworkClient

final class MockSyncTokenManager: SyncTokenProvider {
    var refreshTokenAPI: URLGenerator = MockAPI.endpoint
    var headers: [String : String] = [:]
    
    private(set) var requestTokenCalled = false
    func requestToken(completionQueue: DispatchQueue, completion: @escaping (Result<String?, TokenManagerError>) -> Void) {
        requestTokenCalled = true
    }
    
    private(set) var requestRefreshTokenCalled = false
    func requestRefreshToken() -> String? {
        requestRefreshTokenCalled = true
        return nil
    }
    
    private(set) var requestBodyDataCalled = false
    func requestBodyData() -> [String : Any] {
        requestBodyDataCalled = true
        return [:]
    }
    
    private(set) var updateTokenCalled = false
    func updateToken(newToken: String, completionQueue: DispatchQueue, completion: @escaping (Result<String?, TokenManagerError>) -> Void) {
        updateTokenCalled = true
    }
    
    private(set) var updateTokenDataCalled = false
    func updateToken(data: Data?, completionQueue: DispatchQueue, completion: @escaping (Result<String?, TokenManagerError>) -> Void) {
        updateTokenDataCalled = true
        completion(.success("testtoken"))
    }
    
    private(set) var setDataCalled = false
    func setData(clientSecret: String, clientID: String, refreshToken: String?, token: String?) {
        setDataCalled = true
    }
}
