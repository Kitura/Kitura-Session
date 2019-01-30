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

// MARK CookieParameter

/// The parameters for configuring the cookies used to send the session IDs to the clients.
///
/// ### Usage Example: ###
/// ```swift
/// let session = Session(secret: "Something very secret", cookie: [.name("mySessionId")])
/// router.all(middleware: session)
/// ```
/// In the example, an instance of `Session` is created with a custom value for the `CookieParameter` name.
public enum CookieParameter {

    /// The cookie's name. Defaults to "kitura-session-id".
    case name(String)

    /// The cookie's path attribute. This specifies the path for which the cookie is valid. The client should only provide this cookie for requests on this path.
    case path(String)

    /// The cookie's secure attribute, indicating whether the cookie should be provided only
    /// over secure (https) connections. Defaults to false.
    case secure(Bool)

    /// The cookie's maxAge attribute, that is, the maximum age (in seconds) from the time of issue that
    /// the cookie should be kept for. Defaults to -1.0, i.e. no expiration.
    case maxAge(TimeInterval)
}
