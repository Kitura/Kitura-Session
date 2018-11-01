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

// MARK SessionState

/// A set of helper functions to manipulate session data.
public class SessionState {

    /// The session ID.
    public let id: String

    /// Dirty flag
    internal private(set) var isDirty = false

    /// Empty flag
    internal var isEmpty: Bool { return state.isEmpty }

    /// Actual session state
    private var state: [String: Any]

    /// Store for session state
    private let store: Store

    internal init(id: String, store: Store) {
        self.id = id
        self.store = store
        state = [String: Any]()
    }

    /// Reload the session data from the session `Store`.
    ///
    /// - Parameter callback: The closure to invoke once the reading of session data is complete.
    public func reload(callback: @escaping (NSError?) -> Void) {
        store.load(sessionId: id) {(data: Data?, error: NSError?) in
            if  error == nil {
                if  let data = data,
                    let state = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String:Any] {
                    self.state = state
                } else {
                    // Not found in store
                    self.state = [:]
                }
                self.isDirty = false
            }
            callback(error)
        }
    }

    /// Save the session data to the session `Store`.
    ///
    /// - Parameter callback: The closure to invoke once the writing of session data is complete.
    public func save(callback: @escaping (NSError?) -> Void) {
        do {
            let data = try JSONSerialization.data(withJSONObject: self.state, options: [])
            store.save(sessionId: id, data: data, callback: callback)
        } catch {
            #if os(Linux)
                let err = NSError(domain: error.localizedDescription, code: -1)
            #else
                let err = error as NSError
            #endif

            callback(err)
        }
    }

    /// Delete the session data from the session `Store`.
    ///
    /// - Parameter callback: The closure to invoke once the deletion of session data is complete.
    public func destroy(callback: @escaping (NSError?) -> Void) {
        store.delete(sessionId: id) { error in
            self.state = [:]
            self.isDirty = false
            callback(error)
        }
    }

    /// Remove an entry from the session data.
    ///
    /// - Parameter key: The key of the entry to delete.
    public func remove(key: String) {
        state[key] = nil
        isDirty = true
    }

    /// Retrieve an entry from the session data.
    ///
    /// - Parameter key: The key of the entry to retrieve.
    public subscript(key: String) -> Any? {
        get {
            return state[key]
        }
        set {
            state[key] = newValue
            isDirty = true
        }
    }
    // MARK: Codable session
    
    /**
     Encode an encodable value as JSON and store it in the session for the provided key.
     ### Usage Example: ###
     The example below defines a `User` struct.
     It decodes a `User` instance from the request body
     and stores it in the request session using the user's id as the key.
     ```swift
     public struct User: Codable {
        let id: String
        let name: String
     }
     let router = Router()
     router.all(middleware: Session(secret: "secret"))
     router.post("/user") { request, response, next in
         let user = try request.read(as: User.self)
         try request.session?.add(user, forKey: user.id)
         response.status(.created)
         response.send(user)
         next()
     }
     ```
     - Parameter value: The Encodable object which will be added to the session.
     - Parameter forKey: The key that the Encodable object will be stored under.
     - Throws: `EncodingError` if value to be stored fails to be encoded as JSON.
     - Throws: `SessionCodingError.failedToSerializeJSON` if value to be stored fails to be serialized as JSON.
     */
    public func add<T: Encodable>(_ value: T, forKey key: String) throws {
        let json: Any
        let data = try JSONEncoder().encode(value)
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .collection {
            guard let array = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Any] else {
                throw SessionCodingError.failedToSerializeJSON
            }
            json = array
        } else {
            guard let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                throw SessionCodingError.failedToSerializeJSON
            }
            json = dict
        }
        state[key] = json
        isDirty = true
    }

    /**
     Decode the JSON value that is stored in the session for the provided key as a Decodable object.
     ### Usage Example: ###
     The example below defines a `User` struct.
     It then reads a user id from the query parameters
     and decodes the instance of `User` that is stored in the session for that id.
     ```swift
     public struct User: Codable {
        let id: String
        let name: String
     }
     let router = Router()
     router.all(middleware: Session(secret: "secret"))
     router.get("/user") { request, response, next in
         guard let userID = request.queryParameters["userid"] else {
            return response.status(.notFound).end()
         }
         let user = try request.session?.read(as: User.self, forKey: userID)
         response.status(.OK)
         response.send(user)
         next()
     }
     ```
     - Parameter as: The Decodable object type which the session will be decoded as.
     - Parameter forKey: The key that the Decodable object was stored under.
     - Throws: `SessionCodingError.keyNotFound` if a value is not found for the provided key.
     - Throws: `DecodingError` if value stored for the key fails to be decoded as the provided type.
     - Returns: The instantiated Decodable object
     */
    public func read<T: Decodable>(as type: T.Type, forKey key: String) throws -> T {
        guard let dict = state[key] else {
            throw SessionCodingError.keyNotFound(key: key)
        }
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode(type, from: data)
    }
    
    /**
     Encode a single Codable value as JSON and append it to the array stored in the session for the provided key.
     If no value is present for the provide key, a new array is created with the given value.
     ### Usage Example: ###
     The example below defines a `User` struct.
     It decodes a `User` instance from the request body
    and appends it to the request session array of users.
     ```swift
     public struct User: Codable {
         let id: String
         let name: String
     }
     let router = Router()
     router.all(middleware: Session(secret: "secret"))
     router.post("/user") { request, response, next in
         let user = try request.read(as: User.self)
         try request.session?.append(user, forKey: "user")
         response.status(.created)
         response.send(user)
         next()
     }
     ```
     - Parameter value: The Codable object which will be appended to the session array.
     - Parameter forKey: The key that the Codable array is stored under.
     - Throws: `EncodingError` if value to be stored fails to be encoded as JSON.
     - Throws: `DecodingError` if value stored for the key fails to be decoded as an array of the provided type.
     - Throws: `SessionCodingError.failedToSerializeJSON` if value to be stored fails to be serialized as JSON.
     */
    public func append<T: Codable>(_ value: T, forKey key: String) throws {
        try self.append([value], forKey: key)
    }
    
    /**
     Encode an array of Codable values as JSON and append them to the array stored in the session for the provided key.
     If no value is present for the provide key, the provided array is stored.
     ### Usage Example: ###
     The example below defines a `User` struct.
     It decodes an array of `User` instances from the request body
     and appends them to the request session array of users.
     ```swift
     public struct User: Codable {
         let id: String
         let name: String
     }
     let router = Router()
     router.all(middleware: Session(secret: "secret"))
     router.post("/user") { request, response, next in
         let users = try request.read(as: [User.self])
         try request.session?.append(users, forKey: "users")
         response.status(.created)
         response.send(users)
         next()
     }
     ```
     - Parameter value: The Codable array which will be appended to the session array.
     - Parameter forKey: The key that the Codable array is stored under.
     - Throws: `EncodingError` if value to be stored fails to be encoded as JSON.
     - Throws: `DecodingError` if value stored for the key fails to be decoded as an array of the provided type.
     - Throws: `SessionCodingError.failedToSerializeJSON` if value to be stored fails to be serialized as JSON.
     */
    public func append<T: Codable>(_ value: [T], forKey key: String) throws {
        let array: [T]
        do {
            array = try self.read(as: [T].self, forKey: key)
        } catch is SessionCodingError {
            array = []
        }
        let appendedArray = array + value
        try self.add(appendedArray, forKey: key)
    }
    
    /**
     Encode a dictionary of Codable values as JSON and merge them with the dictionary stored in the session for the provided key.
     If there are duplicate keys when merging the new key value is used.
     If no value is present for the provide key, the provided dictionary is stored.
     ### Usage Example: ###
     The example below defines a `User` struct.
     It decodes a dictionary of `User` instances from the request body
     and merges them with the request sessions dictionary of users.
     ```swift
     public struct User: Codable {
         let id: String
         let name: String
     }
     let router = Router()
     router.all(middleware: Session(secret: "secret"))
     router.post("/user") { request, response, next in
         let users = try request.read(as: [String: User.self])
         try request.session?.append(users, forKey: "users")
         response.status(.created)
         response.send(users)
         next()
     }
     ```
     - Parameter value: The Codable dictionary which will be merged with the session dictionary.
     - Parameter forKey: The key that the Codable dictionary is stored under.
     - Throws: `EncodingError` if value to be stored fails to be encoded as JSON.
     - Throws: `DecodingError` if value stored for the key fails to be decoded as a dictionary of the provided type.
     - Throws: `SessionCodingError.failedToSerializeJSON` if value to be stored fails to be serialized as JSON.
     */
    public func append<K: Codable, V: Codable>(_ value: [K: V], forKey key: String) throws {
        let dict: [K: V]
        do {
            dict = try self.read(as: [K: V].self, forKey: key)
        } catch is SessionCodingError {
            dict = [:]
        }
        let appendedDict = dict.merging(value, uniquingKeysWith: { (_, last) in last })
        try self.add(appendedDict, forKey: key)
    }
}




