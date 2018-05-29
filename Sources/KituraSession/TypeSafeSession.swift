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
import LoggerAPI
import KituraContracts

import Foundation

// MARK TypeSafeSession

/// A type-safe middleware for managing user sessions.
public protocol TypeSafeSession: TypeSafeMiddleware, Codable {
    
    // MARK - Static properties used to define how Sessions are configured and stored

    /// Specifies the store for session state, or leave `nil` to use a simple in-memory store.
    /// Note that in-memory stores do not provide support for expiry so should be used for
    /// development and testing purposes only.
    static var store: Store? { get set }
    
    /// An optional array of `CookieParameter`, specifying the cookie's attributes.
    static var cookieSetup: CookieSetup { get }
    
    // MARK - Mandatory instance properties
    
    /// The unique id for this session.
    var sessionId: String { get }
    
    /// Save the current session instance to the store.
    func save() throws
    
    /// Destroy the session, removing it and all its associated data from the store.
    func destroy() throws
    
    /// Create a new instance (an empty session), where the only known value is the
    /// (newly created) session id.
    ///
    /// Existing sessions are restored via the Codable API by decoding a retreived JSON
    /// representation.
    init(sessionId: String)
}

extension TypeSafeSession {
    
    /// Handle an incoming request.
    ///
    /// - Parameter request: The `RouterRequest` object used to get information
    ///                     about the request.
    /// - Parameter response: The `RouterResponse` object used to respond to the
    ///                       request.
    /// - Parameter completion: The closure to invoke once middleware processing
    ///                         is complete. Either an instance of Self or a
    ///                         RequestError should be provided, indicating a
    ///                         successful or failed attempt to process the request.
    public static func handle(request: RouterRequest, response: RouterResponse, completion: @escaping (Self?, RequestError?) -> Void) {
        // If the user's type has not assigned a store, default to an in-memory store
        let store = Self.store ?? InMemoryStore()
        if Self.store == nil {
            Log.info("No session store was specified by \(Self.self), defaulting to in-memory store.")
            Self.store = store
        }
        guard let (sessionId, newSession) = Self.cookieSetup.cookieManager?.getSessionId(request: request, response: response) else {
            // Failure to initialize CookieCryptography - error logged in cookieConfiguration getter
            return completion(nil, .internalServerError)
        }
        if newSession {
            Log.verbose("Creating new session: \(sessionId)")
            guard let cookieManager = Self.cookieSetup.cookieManager, cookieManager.addCookie(sessionId: sessionId, domain: request.hostname, response: response) else {
                // This is presumably a failure of Cookie Cryptography, which is likely a server misconfiguration.
                // It is not possible to issue a session cookie to the client.
                // TODO: Options: we could fail, or we could continue on anyway without a session.
                // Danger of continuing is that we might store things into the session, and persist it,
                // with no way of retreiving it again.
                // - we have opted to fail
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
                        // TODO: Options: we could fail, or we could log the error and create a new session.
                        // - we've opted to fail here
                        Log.error("Unable to deserialize saved session for sessionId=\(sessionId), with error: \(error)")
                        return completion(nil, .internalServerError)
                    }
                } else {
                    // This is okay - a valid cookie was provided but no session could be found in the store.
                    // The session may have timed out, been purged (eg. user logged out) or server was restarted.
                    Log.verbose("Creating new session \(sessionId) as a saved session was not found in the store.")
                    return completion(Self(sessionId: sessionId), nil)
                }
            }
        }
    }
    
    /// Save the current session instance to the store
    public func save() throws {
        guard let store = Self.store else {
            Log.error("Unexpectedly found a nil store")
            return
        }
        let encoder = JSONEncoder()
        do {
            let selfData: Data = try encoder.encode(self)
            store.save(sessionId: self.sessionId, data: selfData) { error in
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
    
    /// Destroy the session, removing it and all its associated data from the store
    public func destroy() throws {
        guard let store = Self.store else {
            Log.error("Unexpectedly found a nil store")
            return
        }
        store.delete(sessionId: self.sessionId) { error in
            if let error = error {
                Log.error("Failed to delete session data for session: \(self.sessionId) with error: \(error)")
            }
        }
    }

}
