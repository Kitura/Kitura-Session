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

/**
 A `TypeSafeMiddleware` for managing user sessions. The user defines a final class with the fields they wish to use within  the session. This class can then save or destroy itself from a static `Store`, which is keyed by a `sessionId`. The sessionId can be extracted from the session cookie to initialise an instance of the users class with the session data. If no store is defined, the session will default to an in-memory store.
 ### Usage Example: ###
 In this example, a class conforming to the TypeSafeSession protocol is defined containing an optional "name" field. Then a route on "/session" is set up that stores a received name into the session.
 ```swift
 final class MySession: TypeSafeSession {
    var name: String?
 
    let sessionId: String
    init(sessionId: String) {
        self.sessionId = sessionId
    }
     static var store: Store?
     static let sessionCookie = SessionCookie(name: "session-cookie", secret: "abc123")
 }
 
 router.post("/session") { (session: MySession, name: String, respondWith: (String?, RequestError?) -> Void) in
    session.name = name
    try? session.save()
    respondWith(session.name, nil)
 }
 ```
 __Note__: When using multiple TypeSafeSession classes together, If the cookie names are the same, the cookie secret must also be the same. Otherwise the sessions will conflict and overwrite each others cookies. (Different cookie names can use different secrets)
 */
public protocol TypeSafeSession: TypeSafeMiddleware, Codable, AnyObject {

    // MARK: Static class properties

    /// Specifies the `Store` for session state, or leave `nil` to use a simple in-memory store.
    /// Note that in-memory stores do not provide support for expiry so should be used for
    /// development and testing purposes only.
    static var store: Store? { get set }

    /// A `SessionCookie` that defines the session cookie's name and attributes.
    static var sessionCookie: SessionCookie { get }

    // MARK: Mandatory instance properties

    /// The unique id for this session.
    var sessionId: String { get }

    /// Create a new instance (an empty session), where the only known value is the
    /// (newly created) session id. Non-optional fields must be given a default value.
    ///
    /// Existing sessions are restored via the Codable API by decoding a retreived JSON
    /// representation.
    init(sessionId: String)

    // MARK: Functions implemented in extension

    /// Save the current session instance to the store.
    func save() throws

    /// Destroy the session, removing it and all its associated data from the store.
    func destroy() throws
}

extension TypeSafeSession {

    /// Static handle function that will try and create an instance if Self. It will check the request for the session cookie. If the cookie is not present it will create a cookie and initialize a new session for the user. If a session cookie is found, this function will decode and return an instance of itself from the store.
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
        guard let (sessionId, newSession) = Self.sessionCookie.cookieManager?.getSessionId(request: request, response: response) else {
            // Failure to initialize CookieCryptography - error logged in cookieConfiguration getter
            return completion(nil, .internalServerError)
        }
        if newSession {
            Log.verbose("Creating new session: \(sessionId)")
            guard let cookieManager = Self.sessionCookie.cookieManager, cookieManager.addCookie(sessionId: sessionId, domain: request.hostname, response: response) else {
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

    /**
     Save the current session instance to the store
     ### Usage Example: ###
     ```swift
     router.post("/session") { (session: MySession, name: String, respondWith: (String?, RequestError?) -> Void) in
         session.name = name
         try? session.save()
         respondWith(session.name, nil)
     }
     ```
     */
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

    /**
     Destroy the session, removing it and all its associated data from the store
     ### Usage Example: ###
     ```swift
     router.delete("/session") { (session: MySession, respondWith: (RequestError?) -> Void) in
         try? session.destroy()
         respondWith(nil)
     }
     ```
     */
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
