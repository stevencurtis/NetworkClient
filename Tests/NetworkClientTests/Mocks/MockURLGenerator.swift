import Foundation
@testable import NetworkClient

struct MockURLGenerator: URLGenerator {
    var url: URL? = URL(string: "https://www.google.com")
}
