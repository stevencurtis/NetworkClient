//  Created by Steven Curtis

import Foundation

public protocol TokenProvider {
    func requestToken() async throws -> String?
    func requestRefreshToken() async throws -> String?
    func requestBodyData() async throws -> [String: Any]
    func setData(clientSecret: String, clientID: String, refreshToken: String?, token: String?) async
    func updateToken(_ data: Data?) async
    var refreshTokenAPI: URLGenerator { get async }
    var headers: [String : String] { get async }
}
