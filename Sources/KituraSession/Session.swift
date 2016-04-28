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

///
/// Session middleware
///
public class Session: RouterMiddleware {

    //
    // Store for session state
    //
    private let store: Store

    //
    // Cookie manager
    //
    private let cookieManager: CookieManagement

    ///
    /// Initializes a new Session management middleware
    ///
    /// - Parameter secret: The string used to encrypt the session id cookie
    public init(secret: String, cookie: [CookieParm]?=nil, store: Store?=nil) {
        if  let store = store {
            self.store = store
        }
        else {
            // No store provided
            Log.warning("Using default in-memory session store")
            self.store = InMemoryStore()
        }

        cookieManager = CookieManagement(secret: secret, cookieParms: cookie)
    }

    public func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        let (sessionId, newSession) = cookieManager.getSessionId(request: request, response: response)
        if  let sessionId = sessionId  {
            let session = SessionState(id: sessionId, store: store)
            var previousPreFlushHandler: PreFlushLifecycleHandler? = nil
            let preFlushHandler: PreFlushLifecycleHandler = {request, response in
                if  let session = request.session {
                    if  newSession  &&  !session.isEmpty  {
                        self.cookieManager.addCookie(sessionId: session.id, domain: request.hostname, response: response)
                    }
                    if  session.isDirty  {
                        session.save() {error in
                            if  error != nil  {
                                Log.error("Failed to save session data for session \(session.id)")
                            }
                        }
                    }
                    else  {
                        if  !session.isEmpty  {
                            self.store.touch(sessionId: session.id) {error in
                                if  error != nil  {
                                    Log.error("Failed to \"touch\" session for session \(session.id)")
                                }
                            }
                        }
                    }
                }
                previousPreFlushHandler!(request: request, response: response)
            }
            previousPreFlushHandler = response.setPreFlushHandler(preFlushHandler)

            if  newSession {
                request.session = session
                next()
            }
            else {
                session.reload() {error in
                    if  let error = error  {
                        // Failed to load data from store,
                        Log.error("Failed to load session data from store. Error=\(error)")
                    }
                    else {
                        request.session = session
                    }
                    next()
                }
            }
        }
        else {
            // Failed to decrypt the cookie
            next()
        }
    }
}

public enum CookieParm {
    case Name(String), Path(String), Secure(Bool), MaxAge(NSTimeInterval)
}

public protocol Store {
    func load(sessionId: String, callback: (data: NSData?, error: NSError?) -> Void)
    func save(sessionId: String, data: NSData, callback: (error: NSError?) -> Void)
    func touch(sessionId: String, callback: (error: NSError?) -> Void)
    func delete(sessionId: String, callback: (error: NSError?) -> Void)
}
