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
    // Secret used to encrypt/decrypt a cookie
    private let secret: String
    
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
    private let maxAge: NSTimeInterval
    
    
    internal init(secret: String, cookieParms: [CookieParameter]?) {
        var name = "kitura-session-id"
        var path = "/"
        var secure = false
        var maxAge = -1.0
        if  let cookieParms = cookieParms  {
            for  parm in cookieParms  {
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

        self.secret = secret
        self.name = name
        self.path = path
        self.secure = secure
        self.maxAge = maxAge

    }


    internal func getSessionId(request: RouterRequest, response: RouterResponse) -> (String?, Bool) {
        var sessionId: String? = nil
        var newSession = false

        if  let cookie = request.cookies[name]  {
            sessionId = cookie.value
        }
        else {
            // No Cookie
            #if os(Linux)
                sessionId = NSUUID().UUIDString
            #else
                sessionId = NSUUID().uuidString
            #endif
            newSession = true
        }
        return (sessionId, newSession)
    }
    
    
    internal func addCookie(sessionId: String, domain: String, response: RouterResponse) {
        
        #if os(Linux)
            typealias PropValue = Any
        #else
            typealias PropValue = AnyObject
        #endif
        
        var properties: [String: PropValue] = [NSHTTPCookieName: name,
                                               NSHTTPCookieValue: sessionId,
                                               NSHTTPCookieDomain: domain,
                                               NSHTTPCookiePath: path]
        if  secure  {
            properties[NSHTTPCookieSecure] = "Yes"
        }
        if  maxAge > 0.0  {
            properties[NSHTTPCookieMaximumAge] = String(Int(maxAge))
            properties[NSHTTPCookieVersion] = "1"
        }
        let cookie = NSHTTPCookie(properties: properties)
        response.cookies[name] = cookie
    }
}
