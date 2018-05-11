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
import KituraContracts

import Foundation

// MARK Session

/// A pluggable middleware for managing user sessions.
public protocol CodableSession: TypedMiddleware, Codable {
    
    // MARK - Static properties used to define how Sessions are configured and stored

    /// Store for session state, for example, InMemoryStore.
    static var store: Store { get }
    
    /// Secret for initializing cryptography used to generate session cookies.
    static var secret: String { get }
    
    /// An optional array of the cookie's parameters an attributes.
    static var cookie: [CookieParameter]? { get }
    
    // MARK - Instance properties (User's type can also define any additional Codable properties)
    
    /// The Session id for this Session
    var sessionId: String { get }
    
    /// Create a new instance which is a blank Session. Existing sessions
    /// are created by decoding a stored JSON representation.
    init(sessionId: String)
}

// TODO: This doesn't seem right, I don't like having to have a singleton as this is
// shared across all conformances to CodableSession.
private struct CookieStuff {
    
    /// The cookie crypto engine that will be used to generate secure session cookies.
    let cookieCrypto: CookieCryptography
    
    /// The cookie manager which can retreive existing session IDs from cookies or generate new ones.
    let cookieManager: CookieManagement
    
    init(secret: String, cookieParms: [CookieParameter]?) {
        cookieCrypto = try! CookieCryptography(secret: secret)
        cookieManager = CookieManagement(cookieCrypto: cookieCrypto, cookieParms: cookieParms)
    }
    
    // Workaround so that we can initialize CookieStuff in a static context
    static var singleton: CookieStuff? = nil

}

extension CodableSession {
    
    // Workaround so we can initialize CookieStuff in a static context
    private static var cookieStuff: CookieStuff {
        if let singleton = CookieStuff.singleton {
            return singleton
        } else {
            let singleton = CookieStuff(secret: secret, cookieParms: cookie)
            CookieStuff.singleton = singleton
            return singleton
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
    public static func handle(request: RouterRequest, response: RouterResponse, completion: @escaping (Self?, RequestError?) -> Void) {
        let (sessionId, newSession) = cookieStuff.cookieManager.getSessionId(request: request, response: response)
        if let sessionId = sessionId {
            if newSession {
                Log.verbose("Creating new session: \(sessionId)")  //TODO: remove secret ID from log
                let session = Self(sessionId: sessionId)
                return completion(session, nil)
            } else {
                // We have a session cookie, now we want to decode a saved CodableSession
                store.load(sessionId: sessionId) { data, error in
                    if let error = error {
                        Log.error("Error retreiving session from store: \(error)")
                        return completion(nil, .internalServerError)
                    }
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            let selfInstance: Self = try decoder.decode(Self.self, from: data)
                            return completion(selfInstance, nil)
                        } catch {
                            // We end up here if there is a session serialized in the store, but we couldn't decode it.
                            // Maybe if the store is persistent and the user changes the model?
                            Log.error("Unable to deserialize saved session for sessionId=\(sessionId)")
                            return completion(nil, .internalServerError)
                        }
                    } else {
                        Log.verbose("Creating new session \(sessionId) as user-supplied session cookie could not be retreived from the store.")
                        return completion(Self(sessionId: sessionId), nil)
                    }
                }
            }
        } else {
            // Session cookie was provided, but could not be decrypted - either corrupt, invalid or we changed our key?
            // TODO: Think about this - if a client has a bad cookie then shouldn't we be providing them with a new one (ie. new session)?
            Log.error("Invalid session cookie provided")
            return completion(nil, .badRequest)
        }
    }
    
    // Registers a lifecycle event handler to save the session state if it has been modified during the handling of the request.
    // TODO: How do we detect that a _struct_ has been modified when they are pass by value?
    // Could we use the deinit of the struct to notify us that the handler has completed?
    // Thought...
    // Store the session as raw JSON against the request
    // Store the session again (on deinit) against the request, check if it has changed, ...  but there isn't a deinit on a Struct :(
    // Another thought...
    // What if someone tried to use regular (raw) Session middleware on a raw route and CodableSession on a Codable route?
    private static func registerSessionSaveHandler(request: RouterRequest, response: RouterResponse, newSession: Bool) {
            var previousOnEndInvoked: LifecycleHandler? = nil
            let onEndInvoked = { [weak request, weak response] in
                guard let previousOnEndInvoked = previousOnEndInvoked else {return}
                guard let request = request else {previousOnEndInvoked(); return}
                guard let response = response else {previousOnEndInvoked(); return}
                // XXXXXXXXXXXXXXXX TODO: this is not right yet. We need to get at the Session struct that was passed to the handler
                if  let session = request.session {
                    if  newSession  &&  !session.isEmpty {
                        guard cookieStuff.cookieManager.addCookie(sessionId: session.id, domain: request.hostname, response: response) == true else {
                            response.status(.internalServerError)
                            // TODO: Make sure this bug gets fixed in regular Session
                            Log.error("Unable to encrypt new session cookie data")
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
    }
}
