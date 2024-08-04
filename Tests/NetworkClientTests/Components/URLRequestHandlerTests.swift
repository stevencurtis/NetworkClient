//  Created by Steven Curtis

@testable import NetworkClient
import XCTest

final class URLRequestHandlerTests: XCTestCase {
    func testCreateURLRequest_withHeaders() throws {
        let headers = ["Content-Type": "application/json"]
        let handler = URLRequestHandler(headers: headers)
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let api = MockURLGenerator(url: url)
        let request = MockAPIRequest()

        do {
            let urlRequest = try handler.createURLRequest(api: api, request: request)
            XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Content-Type"], "application/json")
        } catch {
            XCTFail("Creating URLRequest failed with error: \(error)")
        }
    }
    
    func testCreateURLRequest_withBearerToken() throws {
        let tokenGenerator: () -> String? = { return "testToken" }
        let handler = URLRequestHandler(
            headers: [:],
            token: .bearer(
                token: tokenGenerator
            )
        )
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let api = MockURLGenerator(url: url)
        let request = MockAPIRequest()
        
        do {
            let urlRequest = try handler.createURLRequest(api: api, request: request)
            XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Bearer testToken")
        } catch {
            XCTFail("Creating URLRequest failed with error: \(error)")
        }
    }
    
    func testCreateURLRequest_withQueryParameterToken() throws {
        let handler = URLRequestHandler(
            headers: [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ],
            token: .queryParameter(
                token: "testToken"
            )
        )
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let api = MockURLGenerator(url: url)
        let request = MockAPIRequest()
        
        do {
            let urlRequest = try handler.createURLRequest(api: api, request: request)
            let urlRequestURL = try XCTUnwrap(urlRequest.url)
            let urlComponents = URLComponents(
                url: urlRequestURL,
                resolvingAgainstBaseURL: false
            )
            let tokenQueryItem = urlComponents?.queryItems?.first(where: {
                $0.name == "access_token"
            })
            XCTAssertEqual(tokenQueryItem?.value, "testToken")
        } catch {
            XCTFail("Creating URLRequest failed with error: \(error)")
        }
    }

    func testCreateURLRequest_withRequestBodyToken() throws {
        let handler = URLRequestHandler(headers: [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ], token: 
                .requestBody(token: "testToken"))
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let api = MockURLGenerator(url: url)
        let request = MockAPIRequest()
        
        do {
            let modifiedRequest = try handler.createURLRequest(api: api, request: request)
            let requestBody = try XCTUnwrap(modifiedRequest.httpBody)
            let bodyDictionary = try JSONSerialization.jsonObject(
                with: requestBody,
                options: []
            ) as? [String: Any]
            XCTAssertEqual(bodyDictionary?["access_token"] as? String, "testToken")
        } catch {
            XCTFail("Creating URLRequest failed with error: \(error)")
        }
    }

    func testCreateURLRequest_withCustomHeaderToken() throws {
        let handler = URLRequestHandler(
            headers: [:],
            token: .customHeader(
                headerName: "Custom-Header",
                token: "testToken"
            )
        )
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        let api = MockURLGenerator(url: url)
        let request = MockAPIRequest()
        
        do {
            let urlRequest = try handler.createURLRequest(api: api, request: request)
            XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Custom-Header"), "testToken")
        } catch {
            XCTFail("Creating URLRequest failed with error: \(error)")
        }
    }
}
