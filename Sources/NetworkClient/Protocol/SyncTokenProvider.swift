import Foundation

public protocol SyncTokenProvider {
    func requestToken(completionQueue: DispatchQueue, completion: @escaping (Result<String?, TokenManagerError>) -> Void)
    func requestRefreshToken() -> String?
    func requestBodyData() -> [String: Any]
    func updateToken(newToken: String, completionQueue: DispatchQueue, completion: @escaping (Result<String?, TokenManagerError>) -> Void)
    func updateToken(data: Data?, completionQueue: DispatchQueue, completion: @escaping (Result<String?, TokenManagerError>) -> Void)
    func setData(clientSecret: String, clientID: String, refreshToken: String?, token: String?)
    var refreshTokenAPI: URLGenerator { get }
    var headers: [String : String] { get }
}
