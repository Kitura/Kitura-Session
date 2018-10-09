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

struct CodableSessionTest: Codable {
    let sessionKey: String
}

let CodableSessionTestArray = ["sessionValue1", "sessionValue2", "sessionValue3"]
let CodableSessionTestDict = ["sessionKey1": "sessionValue1", "sessionKey2": "sessionValue2", "sessionKey3": "sessionValue3"]
let CodableSessionTestCodableArray = [CodableSessionTest(sessionKey: "sessionValue1"), CodableSessionTest(sessionKey: "sessionValue2"), CodableSessionTest(sessionKey: "sessionValue3")]

class TestCodableSession: XCTestCase, KituraTest {
    
    static var allTests: [(String, (TestCodableSession) -> () throws -> Void)] {
        return [
            ("testCodableSessionReadString", testCodableSessionReadString),
            ("testCodableSessionAddString", testCodableSessionAddString),
            ("testCodableSessionAddReadString", testCodableSessionAddReadString),
            ("testCodableSessionReadArray", testCodableSessionReadArray),
            ("testCodableSessionAddArray", testCodableSessionAddArray),
            ("testCodableSessionAddReadArray", testCodableSessionAddReadArray),
            ("testCodableSessionReadCodable", testCodableSessionReadCodable),
            ("testCodableSessionAddCodable", testCodableSessionAddCodable),
            ("testCodableSessionAddReadCodable", testCodableSessionAddReadCodable),
            ("testCodableSessionAddReadDict", testCodableSessionAddReadDict),
            ("testCodableSessionAddReadCodableArray", testCodableSessionAddReadCodableArray),
        ]
    }

    func testCodableSessionReadString() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/raw") {request, response, next in
            request.session?[sessionTestKey] = sessionTestValue
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            guard let codable = try request.session?.read(as: String.self, forKey: sessionTestKey) else {
                return
            }
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "raw", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: {response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return XCTFail()
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString() else {
                            XCTFail("No response body")
                            return
                        }
                        XCTAssertEqual(body, sessionTestValue, "Body \(body)) is not equal to \(sessionTestValue)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }

    func testCodableSessionAddString() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/codable") { request, response, next in
            let codableSession = CodableSessionTest(sessionKey: sessionTestValue)
            try request.session?.add(codableSession.sessionKey, forKey: sessionTestKey)
            response.status(.created)
            next()
        }
        
        router.get("/raw") { request, response, next in
            guard let sessionValue = request.session?[sessionTestKey] as? String else {
                return try response.send(status: .notFound).end()
            }
            response.status(.OK)
            response.send(sessionValue)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/raw", callback: { response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return XCTFail()
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString() else {
                            XCTFail("No response body")
                            return
                        }
                        XCTAssertEqual(body, sessionTestValue, "Body \(String(describing: body)) is not equal to \(sessionTestValue)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }

    func testCodableSessionAddReadString() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/codable") { request, response, next in
            let codableSession = CodableSessionTest(sessionKey: sessionTestValue)
            try request.session?.add(codableSession.sessionKey, forKey: sessionTestKey)
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            guard let codable = try request.session?.read(as: String.self, forKey: sessionTestKey) else {
                return
            }
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: {response in
                    XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                    guard let response = response else {
                        return XCTFail()
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString() else {
                            XCTFail("No response body")
                            return
                        }
                        XCTAssertEqual(body, sessionTestValue, "Body \(String(describing: body)) is not equal to \(sessionTestValue)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
    
    func testCodableSessionReadArray() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/raw") {request, response, next in
            request.session?[sessionTestKey] = CodableSessionTestArray
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            let codable = try request.session?.read(as: [String].self, forKey: sessionTestKey)
            response.status(.OK)
            response.send(codable)
            next()
        }
        
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "raw", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: {response in
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
                        XCTAssertEqual(returnedSession, CodableSessionTestArray, "Body \(String(describing: returnedSession)) is not equal to \(CodableSessionTestArray)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
    
    func testCodableSessionAddArray() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/codable") { request, response, next in
            try request.session?.add(CodableSessionTestArray, forKey: sessionTestKey)
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            let codable = try request.session?.read(as: [String].self, forKey: sessionTestKey)
            response.status(.OK)
            response.send(codable)
            next()
        }
        
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: {response in
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
                        XCTAssertEqual(returnedSession, CodableSessionTestArray, "Body \(String(describing: returnedSession)) is not equal to \(CodableSessionTestArray)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
    
    func testCodableSessionAddReadArray() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/codable") { request, response, next in
            try request.session?.add(CodableSessionTestArray, forKey: sessionTestKey)
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            guard let codable = try request.session?.read(as: [String].self, forKey: sessionTestKey) else {
                return try response.send(status: .notFound).end()
            }
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: {response in
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
                        XCTAssertEqual(returnedSession, CodableSessionTestArray, "Body \(String(describing: returnedSession)) is not equal to \(CodableSessionTestArray)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
    
    func testCodableSessionReadCodable() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/raw") { request, response, next in
            request.session?[sessionTestKey] = [sessionTestKey: sessionTestValue]
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            let codable = try request.session?.read(as: CodableSessionTest.self, forKey: sessionTestKey)
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "raw", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: {response in
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
                        XCTAssertEqual(returnedSession.sessionKey, sessionTestValue, "Body \(String(describing: returnedSession.sessionKey)) is not equal to \(sessionTestValue)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
    
    func testCodableSessionAddCodable() {
        let router = Router()
        router.all(middleware: Session(secret: "secret"))
        
        router.post("/codable") { request, response, next in
            let codableSession = CodableSessionTest(sessionKey: sessionTestValue)
            try request.session?.add(codableSession, forKey: sessionTestKey)
            response.status(.created)
            next()
        }
        
        router.get("/raw") { request, response, next in
            guard let sessionValue = (request.session?[sessionTestKey] as? [String: String])?[sessionTestKey] else {
                return
            }
            let codable = CodableSessionTest(sessionKey: sessionValue)
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/raw", callback: {response in
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
                        XCTAssertEqual(returnedSession.sessionKey, sessionTestValue, "Body \(String(describing: returnedSession.sessionKey)) is not equal to \(sessionTestValue)")
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
            try request.session?.add(codableSession, forKey: sessionTestKey)
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            let codable = try request.session?.read(as: CodableSessionTest.self, forKey: sessionTestKey)
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: {response in
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
                        XCTAssertEqual(returnedSession.sessionKey, sessionTestValue, "Body \(String(describing: returnedSession.sessionKey)) is not equal to \(sessionTestValue)")
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
            try request.session?.add(CodableSessionTestDict, forKey: sessionTestKey)
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            guard let codable = try request.session?.read(as: [String: String].self, forKey: sessionTestKey) else {
                return try response.send(status: .notFound).end()
            }
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: {response in
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
                        XCTAssertEqual(returnedSession, CodableSessionTestDict, "Body \(String(describing: returnedSession)) is not equal to \(CodableSessionTestDict)")
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
            try request.session?.add(CodableSessionTestCodableArray, forKey: sessionTestKey)
            response.status(.created)
            next()
        }
        
        router.get("/codable") { request, response, next in
            guard let codable = try request.session?.read(as: [CodableSessionTest].self, forKey: sessionTestKey) else {
                return try response.send(status: .notFound).end()
            }
            response.status(.OK)
            response.send(codable)
            next()
        }
        performServerTest(router: router, asyncTasks: {
            self.performRequest(method: "post", path: "codable", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let response = response else {
                    return XCTFail()
                }
                let (cookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                XCTAssertNotNil(cookie, "Cookie \(cookieDefaultName) wasn't found in the response.")
                guard let cookieValue = cookie?.value else {
                    return XCTFail()
                }
                self.performRequest(method: "get", path: "/codable", callback: {response in
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
                        XCTAssertEqual(returnedSession.map({$0.sessionKey}), CodableSessionTestCodableArray.map({$0.sessionKey}), "Body \(String(describing: returnedSession)) is not equal to \(CodableSessionTestCodableArray)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["Cookie": "\(cookieDefaultName)=\(cookieValue)"])
            })
        })
    }
}
