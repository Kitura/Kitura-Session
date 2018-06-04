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

let sessionTestValueTwo = "sessionValueTwo"
let sessionTestValueThree = "sessionValueThree"
let cookieThreeName = "different-session-id"

class TestTypeSafeSession: XCTestCase, KituraTest {

    static var allTests: [(String, (TestTypeSafeSession) -> () throws -> Void)] {
        return [
            ("testTypeSafeSession", testTypeSafeSession),
            ("testTwoSessionsSameCookie", testTwoSessionsSameCookie),
            ("testTwoSessionsDifferentCookie", testTwoSessionsDifferentCookie),
            ("testTypeSafeSessionsMalformedCookie", testTypeSafeSessionsMalformedCookie),
        ]
    }

    func testTypeSafeSession() {
        let router = setupCodableSessionRouter()
        performServerTest(router: router, asyncTasks: {
            // Login to create the session and set session.sessionTestKey to be sessionTestValue
            self.performRequest(method: "get", path: "/login", callback: { response in
                guard let response = response else {
                    return XCTFail("ERROR!!! ClientRequest response object was nil")
                }
                let (responseCookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                guard let cookie = responseCookie else {
                    return XCTFail("Cookie \(cookieDefaultName) wasn't found in the response.")
                }
                // Request the current session and check session.sessionTestKey is still sessionTestValue
                self.performRequest(method: "get", path: "/getSession", callback: { response in
                    guard let response = response else {
                        return XCTFail("ERROR!!! ClientRequest response object was nil")
                    }
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString(), let sessionData = body.data(using: .utf8) else {
                            XCTFail("No response body")
                            return
                        }
                        let decoder = JSONDecoder()
                        let returnedSession = try decoder.decode(MySession.self, from: sessionData)
                        XCTAssertEqual(returnedSession.sessionTestKey, sessionTestValue, "Body \(String(describing: returnedSession.sessionTestKey)) is not equal to \(sessionTestValue)")
                    } catch {
                        XCTFail("No response body")
                    }
                    // Destroy the current session making session.sessionTestKey nil
                    self.performRequest(method: "get", path: "/logout", callback: { response in
                        guard response != nil else {
                            return XCTFail("ERROR!!! ClientRequest response object was nil")
                        }
                        // Request the current session, in which session.sessionTestKey should be nil
                        self.performRequest(method: "get", path: "/getSession", callback: { response in
                            guard let response = response else {
                                return XCTFail("ERROR!!! ClientRequest response object was nil")
                            }
                            XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                            do {
                                // Decode the response into a MySession and check sessionTestKey
                                guard let body = try response.readString(), let sessionData = body.data(using: .utf8) else {
                                    XCTFail("No response body")
                                    return
                                }
                                let decoder = JSONDecoder()
                                let returnedSession = try decoder.decode(MySession.self, from: sessionData)
                                XCTAssertEqual(returnedSession.sessionTestKey, nil, "Body \(String(describing: returnedSession.sessionTestKey)) is not equal to \(sessionTestValue)")
                            } catch {
                                XCTFail("No response body")
                            }
                        }, headers: ["cookie": "\(cookie.name)=\(cookie.value)"])
                    }, headers: ["cookie": "\(cookie.name)=\(cookie.value)"])
                }, headers: ["cookie": "\(cookie.name)=\(cookie.value)"])
            })
        })
    }

    func testTwoSessionsSameCookie() {
        let router = setupCodableSessionRouter()
        performServerTest(router: router, asyncTasks: {
            // Login to create the session and set session.sessionTestKey to be sessionTestValue
            self.performRequest(method: "get", path: "/login", callback: { response in
                guard let response = response else {
                    return XCTFail("ERROR!!! ClientRequest response object was nil")
                }
                let (responseCookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                guard let cookieOne = responseCookie else {
                    return XCTFail("Cookie \(cookieDefaultName) wasn't found in the response.")
                }
                // Login to the second session using the first cookie and set session.sessionTestKeyTwo to be sessionTestValueTwo
                self.performRequest(method: "get", path: "/loginTwo", callback: { response in
                    guard response != nil else {
                        return XCTFail("ERROR!!! ClientRequest response object was nil")
                    }
                    // Request the current sessions and check session.sessionTestKeys are still sessionTestValues
                    self.performRequest(method: "get", path: "/getSessionOneTwo", callback: { response in
                        guard let response = response else {
                            return XCTFail("ERROR!!! ClientRequest response object was nil")
                        }
                        XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                        do {
                            // Decode the response into a SessionOneTwo and check sessionTestKeys
                            guard let body = try response.readString(), let sessionData = body.data(using: .utf8) else {
                                XCTFail("No response body")
                                return
                            }
                            let decoder = JSONDecoder()
                            let returnedSession = try decoder.decode(SessionOneTwo.self, from: sessionData)
                            XCTAssertEqual(returnedSession.sessionOne.sessionTestKey, sessionTestValue, "Body \(String(describing: returnedSession.sessionOne.sessionTestKey)) is not equal to \(sessionTestValue)")
                            XCTAssertEqual(returnedSession.sessionTwo.sessionTestKeyTwo, sessionTestValueTwo, "Body \(String(describing: returnedSession.sessionTwo.sessionTestKeyTwo)) is not equal to \(sessionTestValueTwo)")
                        } catch {
                            XCTFail("No response body")
                        }
                    }, headers: ["cookie": "\(cookieOne.name)=\(cookieOne.value)"])
                }, headers: ["cookie": "\(cookieOne.name)=\(cookieOne.value)"])
            })
        })
    }

    func testTwoSessionsDifferentCookie() {
        let router = setupCodableSessionRouter()
        performServerTest(router: router, asyncTasks: {
            // Login to create the session and set session.sessionTestKey to be sessionTestValue
            self.performRequest(method: "get", path: "/login", callback: { response in
                guard let response = response else {
                    return XCTFail("ERROR!!! ClientRequest response object was nil")
                }
                let (responseCookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                guard let cookieOne = responseCookie else {
                    return XCTFail("Cookie \(cookieDefaultName) wasn't found in the response.")
                }
                // Login to the second session using a new cookie and set session.sessionTestKeyThree to be sessionTestValueThree
                self.performRequest(method: "get", path: "/loginThree", callback: { response in
                    guard let response = response else {
                        return XCTFail("ERROR!!! ClientRequest response object was nil")
                    }
                    let (responseCookie, _) = CookieUtils.cookieFrom(response: response, named: cookieThreeName)
                    guard let cookieThree = responseCookie else {
                        return XCTFail("Cookie \(cookieThreeName) wasn't found in the response.")
                    }
                    // Request the current sessions and check session.sessionTestKeys are still sessionTestValues
                    self.performRequest(method: "get", path: "/getSessionOneThree", callback: { response in
                        guard let response = response else {
                            return XCTFail("ERROR!!! ClientRequest response object was nil")
                        }
                        XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                        do {
                            // Decode the response into a SessionOneThree and check sessionTestKeys
                            guard let body = try response.readString(), let sessionData = body.data(using: .utf8) else {
                                XCTFail("No response body")
                                return
                            }
                            let decoder = JSONDecoder()
                            let returnedSession = try decoder.decode(SessionOneThree.self, from: sessionData)
                            XCTAssertEqual(returnedSession.sessionOne.sessionTestKey, sessionTestValue, "Body \(String(describing: returnedSession.sessionOne.sessionTestKey)) is not equal to \(sessionTestValue)")
                            XCTAssertEqual(returnedSession.sessionThree.sessionTestKeyThree, sessionTestValueThree, "Body \(String(describing: returnedSession.sessionThree.sessionTestKeyThree)) is not equal to \(sessionTestValueThree)")
                        } catch {
                            XCTFail("No response body")
                        }
                    }, headers: ["cookie": "\(cookieOne.name)=\(cookieOne.value);\(cookieThree.name)=\(cookieThree.value)"])
                }, headers: ["cookie": "\(cookieOne.name)=\(cookieOne.value)"])
            })
        })
    }

    func testTypeSafeSessionsMalformedCookie() {
        let router = setupCodableSessionRouter()
        performServerTest(router: router, asyncTasks: {
            // Login to create the session and set session.sessionTestKey to be sessionTestValue
            self.performRequest(method: "get", path: "/login", callback: { response in
                guard let response = response else {
                    return XCTFail("ERROR!!! ClientRequest response object was nil")
                }
                let (responseCookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                guard let cookieOne = responseCookie else {
                    return XCTFail("Cookie \(cookieDefaultName) wasn't found in the response.")
                }
                // Request the current session with a malformed cookie
                self.performRequest(method: "get", path: "/getSession", callback: { response in
                    guard let response = response else {
                        return XCTFail("ERROR!!! ClientRequest response object was nil")
                    }
                    let (responseCookie, _) = CookieUtils.cookieFrom(response: response, named: cookieDefaultName)
                    guard let newCookie = responseCookie else {
                        return XCTFail("Cookie \(cookieDefaultName) wasn't found in the response.")
                    }
                    // Since cookie was malformed, a new cookie is generated.
                    XCTAssertNotEqual(newCookie, cookieOne, "Body \(newCookie)) is not equal to \(cookieOne)")
                    XCTAssertEqual(response.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response.statusCode)")
                    do {
                        guard let body = try response.readString(), let sessionData = body.data(using: .utf8) else {
                            XCTFail("No response body")
                            return
                        }
                        let decoder = JSONDecoder()
                        let returnedSession = try decoder.decode(MySession.self, from: sessionData)
                        // Since this is a new session the sessionTestKey shouldn't be set and should be nil.
                        XCTAssertEqual(returnedSession.sessionTestKey, nil, "Body \(String(describing: returnedSession.sessionTestKey)) is not equal to \(sessionTestValue)")
                    } catch {
                        XCTFail("No response body")
                    }
                }, headers: ["cookie": "\(cookieDefaultName)=RandomIncorrectString"])
            })
        })
    }

    func setupCodableSessionRouter() -> Router {
        let router = Router()

        router.get("/login") { (session: MySession, respondWith: (MySession?, RequestError?) -> Void) in
            session.sessionTestKey = sessionTestValue
            session.save()
            respondWith(session, nil)
        }

        router.get("/loginTwo") { (session: MySessionTwo, respondWith: (MySessionTwo?, RequestError?) -> Void) in
            session.sessionTestKeyTwo = sessionTestValueTwo
            session.save()
            respondWith(session, nil)
        }

        router.get("/loginThree") { (session: MySessionThree, respondWith: (MySessionThree?, RequestError?) -> Void) in
            session.sessionTestKeyThree = sessionTestValueThree
            session.save()
            respondWith(session, nil)
        }

        router.get("/getSession") { (session: MySession, respondWith: (MySession?, RequestError?) -> Void) in
            respondWith(session, nil)
        }

        router.get("/getSessionOneTwo") { (sessionOne: MySession, sessionTwo: MySessionTwo, respondWith: (SessionOneTwo?, RequestError?) -> Void) in
            let multiSession = SessionOneTwo(sessionOne: sessionOne, sessionTwo: sessionTwo)
            respondWith(multiSession, nil)
        }

        router.get("/getSessionOneThree") { (sessionOne: MySession, sessionThree: MySessionThree, respondWith: (SessionOneThree?, RequestError?) -> Void) in
            let multiSession = SessionOneThree(sessionOne: sessionOne, sessionThree: sessionThree)
            respondWith(multiSession, nil)
        }

        router.get("/logout") { (session: MySession, respondWith: (MySession?, RequestError?) -> Void) in
            session.destroy()
            respondWith(session, nil)
        }

        return router
    }

    final class MySession: TypeSafeSession {
        var sessionTestKey: String?

        let sessionId: String
        init(sessionId: String) {
            self.sessionId = sessionId
        }
        static var store: Store?
        static let sessionCookie = SessionCookie(name: cookieDefaultName, secret: "secret")
    }

    final class MySessionTwo: TypeSafeSession {
        var sessionTestKeyTwo: String?

        let sessionId: String
        init(sessionId: String) {
            self.sessionId = sessionId
        }
        static var store: Store?
        static let sessionCookie = SessionCookie(name: cookieDefaultName, secret: "secret")
    }

    final class MySessionThree: TypeSafeSession {
        var sessionTestKeyThree: String?

        let sessionId: String
        init(sessionId: String) {
            self.sessionId = sessionId
        }
        static var store: Store?
        static let sessionCookie = SessionCookie(name: cookieThreeName, secret: "different secret")
    }

    struct SessionOneTwo: Codable {
        let sessionOne: MySession
        let sessionTwo: MySessionTwo
    }

    struct SessionOneThree: Codable {
        let sessionOne: MySession
        let sessionThree: MySessionThree
    }
}
