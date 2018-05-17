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
public protocol TypedSession: TypedMiddleware, Codable {
    
    // MARK - Static properties used to define how Sessions are configured and stored

    /// Specifies the store for session state, or leave `nil` to use a simple in-memory store.
    /// Note that in-memory stores do not provide support for expiry so should be used for
    /// development and testing purposes only.
    static var store: Store? { get set }
    
    /// Secret for initializing cryptography used to generate session cookies. This is
    /// sensitive data that should never be exposed to a client.
    static var secret: String { get }
    
    /// An optional array of the cookie's parameters an attributes.
    /// TODO: example of usage
    static var cookie: [CookieParameter]? { get }
    
    // MARK - Instance properties (User's type can also define any additional Codable properties)
    
    /// The secret, unencrypted session id for this Session. This is sensitive data which
    /// should be kept safe and never exposed to a client.
    var sessionId: String { get }
    
    /// Save the current session instance to the store
    func save() throws
    
    /// Destroy the session, removing it and all its associated data from the store
    func destroy() throws
    
    /// Create a new instance which is a blank Session. Existing sessions
    /// are instead created by decoding a stored JSON representation.
    init(sessionId: String)
}

// The configuration of the Cookies used for a Session is configurable by the user and
// is defined statically on their type via the CookieParameters. This type is used to
// associate the functionality and configuration for handling cookies with the user's type.
private struct CookieConfiguration {
    
    /// The cookie crypto engine that will be used to generate secure session cookies.
    let cookieCrypto: CookieCryptography
    
    /// The cookie manager which can retreive existing session IDs from cookies or generate new ones.
    let cookieManager: CookieManagement
    
    init(secret: String, cookieParms: [CookieParameter]?) {
        cookieCrypto = try! CookieCryptography(secret: secret)
        cookieManager = CookieManagement(cookieCrypto: cookieCrypto, cookieParms: cookieParms)
    }
    
    // A dictionary of CookieConfiguration instances, keyed by a String that uniquely identifies
    // the user's CodableSession type. This is used to associate a single instance of
    // CookieConfiguration with each CodableSession type, without exposing a placeholder for it
    // on the user's type (via the protocol).
    static var configurationForType: [String: CookieConfiguration] = [:]

}

extension TypedSession {
    
    // Initialize the CookieConfiguration in a static context, associating an instance
    // with the user's type.
    // TODO: This is currently using a combination of the user's type name and the String
    // they define via the static describe() function as a key.
    private static var cookieStuff: CookieConfiguration {
        let key: String = "\(Self.self)_".appending(Self.describe())
        if let cookieConfiguration = CookieConfiguration.configurationForType[key] {
            return cookieConfiguration
        } else {
            Log.debug("Associating CodableSession CookieConfiguration with key '\(key)' for type \(Self.self)")
            let cookieConfiguration = CookieConfiguration(secret: secret, cookieParms: cookie)
            CookieConfiguration.configurationForType[key] = cookieConfiguration
            return cookieConfiguration
        }
    }
    
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
        let (sessionId, newSession) = cookieStuff.cookieManager.getSessionId(request: request, response: response)
        if let sessionId = sessionId {
            if newSession {
                Log.verbose("Creating new session: \(sessionId)")  //TODO: remove secret ID from log
                guard cookieStuff.cookieManager.addCookie(sessionId: sessionId, domain: request.hostname, response: response) else {
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
                        Log.verbose("Creating new session \(sessionId) as user-supplied session cookie could not be retreived from the store.")
                        return completion(Self(sessionId: sessionId), nil)
                    }
                }
            }
        } else {
            // Session cookie was provided, but could not be decrypted - either corrupt, invalid or we changed our key?
            // TODO: Options: we could fail, or we could log the error and create a new session.
            // If a client has a bad cookie then shouldn't we be providing them with a new one (ie. new session)?
            // - we've opted to fail for now
            Log.error("Invalid session cookie provided")
            return completion(nil, .badRequest)
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
    
    // Describe the nature of this middleware
    public static func describe() -> String {
        return "Kitura Type-Safe Session"
    }

}
