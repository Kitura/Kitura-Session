/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Kitura
import KituraNet

import Foundation
import XCTest

@testable import KituraSession

struct CodableSessionTest: Codable, Equatable {
    let sessionKey: String
    public static func == (lhs: CodableSessionTest, rhs: CodableSessionTest) -> Bool {
        return lhs.sessionKey == rhs.sessionKey
    }
}
enum SessionEnum: String, Codable {
    case one, two
}
let CodableSessionTestArray = ["sessionValue1", "sessionValue2", "sessionValue3"]
let CodableSessionTestDict = ["sessionKey1": "sessionValue1", "sessionKey2": "sessionValue2", "sessionKey3": "sessionValue3"]
let CodableSessionTestCodableArray = [CodableSessionTest(sessionKey: "sessionValue1"), CodableSessionTest(sessionKey: "sessionValue2"), CodableSessionTest(sessionKey: "sessionValue3")]
let CodableSessionTestCodableDict = ["sessionKey1": CodableSessionTest(sessionKey: "sessionValue1"), "sessionKey2": CodableSessionTest(sessionKey: "sessionValue2"), "sessionKey3": CodableSessionTest(sessionKey: "sessionValue3")]

#if swift(>=4.1)
class TestCodableSession: XCTestCase, KituraTest {
    
    static var allTests: [(String, (TestCodableSession) -> () throws -> Void)] {
        return [
            ("testCodableSessionAddReadArray", testCodableSessionAddReadArray),
            ("testCodableSessionAddReadCodable", testCodableSessionAddReadCodable),
            ("testCodableSessionAddReadDict", testCodableSessionAddReadDict),
            ("testCodableSessionAddReadCodableArray", testCodableSessionAddReadCodableArray),
          ]
    }
  
    func testCodableSessionAddReadArray() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/codable") { request, response, next in
            request.session?[sessionTestKey] = CodableSessionTestArray
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            guard let codable: [String] = request.session?[sessionTestKey] else {
                return try response.send(status: .notFound).end()
            }
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "/codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: { response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return XCTFail()
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString(), let sessionData = body.data(using: .utf8) else {
                            XCTFail("No response body")
                            return
                        }
                        let decoder = JSONDecoder()
                        let returnedSession = try decoder.decode([String].self, from: sessionData)
                        XCTAssertEqual(returnedSession, CodableSessionTestArray)
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
    
    func testCodableSessionAddReadCodable() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/codable") { request, response, next in
            let codableSession = CodableSessionTest(sessionKey: sessionTestValue)
            request.session?[sessionTestKey] = codableSession
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            let codable: CodableSessionTest? = request.session?[sessionTestKey]
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "/codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: { response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return XCTFail()
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString(), let sessionData = body.data(using: .utf8) else {
                            XCTFail("No response body")
                            return
                        }
                        let decoder = JSONDecoder()
                        let returnedSession = try decoder.decode(CodableSessionTest.self, from: sessionData)
                        XCTAssertEqual(returnedSession.sessionKey, sessionTestValue)
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
    
    func testCodableSessionAddReadDict() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/codable") { request, response, next in
            request.session?[sessionTestKey] = CodableSessionTestDict
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            guard let codable: [String: String] = request.session?[sessionTestKey] else {
                return try response.send(status: .notFound).end()
            }
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "/codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: { response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return XCTFail()
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString(), let sessionData = body.data(using: .utf8) else {
                            XCTFail("No response body")
                            return
                        }
                        let decoder = JSONDecoder()
                        let returnedSession = try decoder.decode([String: String].self, from: sessionData)
                        XCTAssertEqual(returnedSession, CodableSessionTestDict)
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
    
    func testCodableSessionAddReadCodableArray() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/codable") { request, response, next in
            request.session?[sessionTestKey] = CodableSessionTestCodableArray
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            guard let codable: [CodableSessionTest] = request.session?[sessionTestKey] else {
                return try response.send(status: .notFound).end()
            }
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "/codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: { response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return XCTFail()
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString(), let sessionData = body.data(using: .utf8) else {
                            XCTFail("No response body")
                            return
                        }
                        let decoder = JSONDecoder()
                        let returnedSession = try decoder.decode([CodableSessionTest].self, from: sessionData)
                        XCTAssertEqual(returnedSession.map({$0.sessionKey}), CodableSessionTestCodableArray.map({$0.sessionKey}))
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
}
#endif
