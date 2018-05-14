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
    
    /// Save the current session instance to the store
    func save()
    
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
                guard cookieStuff.cookieManager.addCookie(sessionId: sessionId, domain: request.hostname, response: response) else {
                    Log.error("Failed to add cookie to response")
                    return completion(nil, .internalServerError)
                }
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
                            Log.error("Unable to deserialize saved session for sessionId=\(sessionId), with error: \(error)")
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
    
    func save() throws {
        let encoder = JSONEncoder()
        do {
            let selfData: Data = try encoder.encode(self)
            Self.store.save(sessionId: self.sessionId, data: selfData) { error in
                if  let error = error {
                    Log.error("Failed to save session data for session: \(self.sessionId) with error: \(error)")
                }
            }
        } catch {
            // We end up here if there is a session serialized in the store, but we couldn't decode it.
            // Maybe if the store is persistent and the user changes the model?
            Log.error("Unable to serialize session for sessionId=\(sessionId), with error: \(error)")
            throw error
        }
    }
}
