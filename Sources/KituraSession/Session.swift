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

// MARK Session

/// A pluggable middleware for managing user sessions.
///
/// In order to use the Session middleware, an instance of `Session` has to be created. In the example
/// below an instance of `Session` is created, then it is connected to the desired path. Two route to are then registered that save and retrieve a `User` from the session.
///
/// ### Usage Example: ###
/// ```swift
/// let session = Session(secret: "Something very secret")
/// router.all(middleware: session)
/// public struct User: Codable {
///     let name: String
/// }
/// router.post("/user") { request, response, next in
///     let user = User(name: "Kitura")
///     request.session?["User"] = user
///     next()
/// }
/// router.get("/user") { request, response, next in
///     let user: User? = request.session?["Kitura"]
///     next()
/// }
/// ```
public class Session: RouterMiddleware {

    /// Store for session state
    private let store: Store

    /// Cookie manager
    private let cookieManager: CookieManagement

    /// Initialize a new `Session` management middleware.
    ///
    /// - Parameter secret: The string used to encrypt the session ID cookie.
    /// - Parameter cookie: An array of the cookie's parameters and attributes.
    /// - Parameter store: The `Store` plugin to be used to store the session state.
    public init(secret: String, cookie: [CookieParameter]?=nil, store: Store?=nil) {
        if  let store = store {
            self.store = store
        } else {
            // No store provided
            Log.warning("Using default in-memory session store")
            self.store = InMemoryStore()
        }
        
        do {
            let cookieCrypto = try CookieCryptography(secret: secret)
            cookieManager = CookieManagement(cookieCrypto: cookieCrypto, cookieParms: cookie)
        } catch {
            Log.error("Error creating CookieCryptography object: \(error)")
            fatalError("Error creating CookieCryptography object: \(error)")
        }
        
        
    }

    
    /// Handle an incoming request.
    ///
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the request.
    /// - Parameter response: The `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter next: The closure to invoke to enable the Router to check for
    ///                  other handlers or middleware to work with this request.
    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
        let (sessionId, newSession) = cookieManager.getSessionId(request: request, response: response)
        let session = SessionState(id: sessionId, store: store)
        var previousOnEndInvoked: LifecycleHandler? = nil
        let onEndInvoked = { [weak request, weak response] in
            guard let previousOnEndInvoked = previousOnEndInvoked else {return}
            guard let request = request else {previousOnEndInvoked(); return}
            guard let response = response else {previousOnEndInvoked(); return}
            if  let session = request.session {
                if !self.cookieManager.cookieExists(response: response) {
                    guard self.cookieManager.addCookie(sessionId: session.id, domain: request.hostname, response: response) == true else {
                        return previousOnEndInvoked()
                    }
                }
                if  session.isDirty {
                    session.save() {error in
                        if  error != nil {
                            Log.error("Failed to save session data for session \(session.id)")
                        }
                    }
                } else {
                    if  !session.isEmpty {
                        self.store.touch(sessionId: session.id) {error in
                            if  error != nil {
                                Log.error("Failed to \"touch\" session for session \(session.id)")
                            }
                        }
                    }
                }
            }
            previousOnEndInvoked()
        }
        previousOnEndInvoked = response.setOnEndInvoked(onEndInvoked)

        if  newSession {
            request.session = session
            next()
        } else {
            session.reload() {error in
                if  let error = error {
                    // Failed to load data from store,
                    Log.error("Failed to load session data from store. Error=\(error)")
                } else {
                    request.session = session
                }
                next()
            }
        }
    }
}
