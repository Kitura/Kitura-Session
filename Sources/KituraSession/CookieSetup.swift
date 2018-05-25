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
import Foundation

public struct CookieSetup {
    
    // MARK - Required parameters
    
    /// The name of the cookie - for example, "kitura-session-id"
    public let name: String
    
    /// The secret used to encrypt the session ID
    public let secret: String
    
    // MARK - Optional parameters
    
    /// Whether the cookie should have the 'secure' flag. Defaults to false.
    public let secure: Bool
    
    // Whether the cookie should have the 'httpOnly' flag. Defaults to true.
    // NOTE: not yet implemented in CookieManagement as NSHTTPCookie doesn't seem to support the HttpOnly flag!
    //public let httpOnly: Bool
    
    /// The path that the client should supply this cookie on. If not set, the cookie
    /// applies to all paths.
    public let path: String?
    
    /// The domain that the client should use this cookie for. If not set, the cookie
    /// will apply only to the subdomain that issued it.
    public let domain: String?
    
    /// The maximum age of this cookie, in seconds. If not set, there is no maximum age.
    public let maxAge: TimeInterval?
    
    /// Create a new CookieSetup instance which controls how session cookies are created.
    /// At minimum, the `name` and `secret` fields must be specified.
    ///
    /// The same `name` value _may_ be used across multiple TypeSafeSession implementations,
    /// resulting in a single session cookie being provided to the client. However in this
    /// case the same `secret` *must* also be used.
    ///
    /// - Parameter name: The name of the cookie, for example, 'kitura-session-id'
    /// - Parameter secret: The secret data used to encrypt and decrypt session cookies with this name
    /// - Parameter secure: Whether the cookie should be provided only over secure (https) connections. Defaults to false
    /// - Parameter path: The path for which this cookie should be supplied. Defaults to allow any path.
    /// - Parameter domain: The domain to which this cookie applies. Defaults to the subdomain of the server issuing the cookie.
    /// - Parameter maxAge: The maximum age (in seconds) from the time of issue that the cookie should be kept for. This is a request to the client and may not be honoured.
    public init(name: String, secret: String, secure: Bool = false, path: String? = nil, domain: String? = nil, maxAge: TimeInterval? = nil) {
        self.name = name
        self.secret = secret
        self.secure = secure
        //self.httpOnly = httpOnly
        self.path = path
        self.domain = domain
        self.maxAge = maxAge
    }
    
}
