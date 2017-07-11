/**
 * Copyright IBM Corporation 2016, 2017
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
import LoggerAPI

import Foundation

internal class CookieManagement {

    //
    // Cookie name
    private let name: String

    //
    // Cookie path
    private let path: String

    //
    // Cookie is secure
    private let secure: Bool

    //
    // Max age of Cookie
    private let maxAge: TimeInterval

    //
    // Cookie encoder/decoder
    private let crypto: CookieCryptography

    internal init(cookieCrypto: CookieCryptography, cookieParms: [CookieParameter]?) {
        var name = "kitura-session-id"
        var path = "/"
        var secure = false
        var maxAge = -1.0
        if  let cookieParms = cookieParms {
            for  parm in cookieParms {
                switch(parm) {
                case .name(let pName):
                    name = pName
                case .path(let pPath):
                    path = pPath
                case .secure(let pSecure):
                    secure = pSecure
                case .maxAge(let pMaxAge):
                    maxAge = pMaxAge
                }
            }
        }

        self.name = name
        self.path = path
        self.secure = secure
        self.maxAge = maxAge

        crypto = cookieCrypto
    }


    internal func getSessionId(request: RouterRequest, response: RouterResponse) -> (String?, Bool) {
        var sessionId: String? = nil
        var newSession = false

        if  let cookie = request.cookies[name],
            let decodedCookieValue = crypto.decode(cookie.value) {
            sessionId = decodedCookieValue
            newSession = false
        } else {
            // No Cookie
            sessionId = UUID().uuidString
            newSession = true
        }
        return (sessionId, newSession)
    }

    internal func addCookie(sessionId: String, domain: String, response: RouterResponse) -> Bool {
        guard let encodedSessionId = crypto.encode(sessionId) else {
            return false
        }

        #if os(Linux)
            var properties: [HTTPCookiePropertyKey: Any] =
                        [HTTPCookiePropertyKey.name: name,
                         HTTPCookiePropertyKey.value: encodedSessionId,
                         HTTPCookiePropertyKey.domain: domain,
                         HTTPCookiePropertyKey.path: path]
            if  secure {
                properties[HTTPCookiePropertyKey.secure] = "Yes"
            }
            if  maxAge > 0.0 {
                properties[HTTPCookiePropertyKey.maximumAge] = String(Int(maxAge))
                properties[HTTPCookiePropertyKey.version] = "1"
            }

        #else
            var properties: [HTTPCookiePropertyKey: AnyObject] =
                        [HTTPCookiePropertyKey.name: name as NSString,
                         HTTPCookiePropertyKey.value: encodedSessionId as NSString,
                         HTTPCookiePropertyKey.domain: domain as NSString,
                         HTTPCookiePropertyKey.path: path as NSString]
            if  secure {
                properties[HTTPCookiePropertyKey.secure] = "Yes" as NSString
            }
            if  maxAge > 0.0 {
                properties[HTTPCookiePropertyKey.maximumAge] = String(Int(maxAge)) as NSString
                properties[HTTPCookiePropertyKey.version] = "1" as NSString
            }
        #endif

        let cookie = HTTPCookie(properties: properties)
        response.cookies[name] = cookie
        return true
    }
}
