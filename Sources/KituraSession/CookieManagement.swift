/**
 * Copyright IBM Corporation 2016
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
    // Cookie domain. If not set, the hostname of the server (as seen by the client)
    // will be used.
    private let domain: String?

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
        self.domain = nil
        self.secure = secure
        self.maxAge = maxAge

        crypto = cookieCrypto
    }

    internal init(sessionName: String, cookieParams: CookieParameters) throws {
        self.name = sessionName
        self.path = cookieParams.path ?? "/"
        self.domain = cookieParams.domain
        self.secure = cookieParams.secure
        self.maxAge = cookieParams.maxAge ?? -1.0
        self.crypto = try CookieCryptography(secret: cookieParams.secret)
    }

    internal func getSessionId(request: RouterRequest, response: RouterResponse) -> (String, Bool) {
        // Try to decrypt the session ID from a cookie supplied by the user
        if  let cookie = request.cookies[name],
            let decodedCookieValue = crypto.decode(cookie.value) {
            return (decodedCookieValue, false)
        } else {
            // We may have added a response cookie in a previous invocation of a TypeSafeSession
            // middleware. In case two TypeSafeSessions share the same cookie name and secret, try
            // to get the corresponding (newly generated) session ID from the response cookie.
            if let cookie = response.cookies[name] {
                if let decodedCookieValue = crypto.decode(cookie.value) {
                    return (decodedCookieValue, false)
                } else {
                    // Sessions that share the same name must also share the same secret for encryption,
                    // as they share a cookie. A failure at this point probably means that the newly
                    // encoded session cookie cannot be decoded because two sessions have the same name
                    // but different secrets.
                    Log.error("Unable to decode session cookie for name=\(name) - possible mismatch of cookie secret")
                    return (UUID().uuidString, true)
                }
            } else {
                // No Cookie, or the cookie could not be decrypted (ie. was corrupt or invalid).
                return (UUID().uuidString, true)
            }
        }
    }

    internal func addCookie(sessionId: String, domain: String, response: RouterResponse) -> Bool {
        guard let encodedSessionId = crypto.encode(sessionId) else {
            return false
        }
        // Allow the user to override the domain for a cookie. If they have not specified
        // a domain, then the domain provided (the hostname of the server as seen by the client)
        // is used.
        let cookieDomain = self.domain ?? domain

        #if os(Linux)
            var properties: [HTTPCookiePropertyKey: Any] =
                        [HTTPCookiePropertyKey.name: name,
                         HTTPCookiePropertyKey.value: encodedSessionId,
                         HTTPCookiePropertyKey.domain: cookieDomain,
                         HTTPCookiePropertyKey.path: path]
            if secure {
                properties[HTTPCookiePropertyKey.secure] = "Yes"
            }
            if maxAge > 0.0 {
                properties[HTTPCookiePropertyKey.maximumAge] = String(Int(maxAge))
                properties[HTTPCookiePropertyKey.version] = "1"
            }

        #else
            var properties: [HTTPCookiePropertyKey: AnyObject] =
                        [HTTPCookiePropertyKey.name: name as NSString,
                         HTTPCookiePropertyKey.value: encodedSessionId as NSString,
                         HTTPCookiePropertyKey.domain: cookieDomain as NSString,
                         HTTPCookiePropertyKey.path: path as NSString]
            if secure {
                properties[HTTPCookiePropertyKey.secure] = "Yes" as NSString
            }
            if maxAge > 0.0 {
                properties[HTTPCookiePropertyKey.maximumAge] = String(Int(maxAge)) as NSString
                properties[HTTPCookiePropertyKey.version] = "1" as NSString
            }
        #endif

        let cookie = HTTPCookie(properties: properties)
        response.cookies[name] = cookie
        return true
    }
}
