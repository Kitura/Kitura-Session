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

    /// Retrieve or store an entry from the session data.
    ///
    /// - Parameter key: The key of the entry to retrieve.
    public subscript(key: String) -> Any? {
        // This function allows you to store values which will fail when you try to serialize them to JSON.
        // This should be removed in the next major release of Kitura-Session in favour of Codable subscript.
        get {
            return state[key]
        }
        set {
            state[key] = newValue
            isDirty = true
        }
    }
    
    /// Retrieve or store a Codable entry from the session data.
    ///
    /// - Parameter key: The Codable key of the entry to retrieve/save.
    // The swift 4.0 compiler fails to go down the Any subscript route if the object is not Codable so this feature can only be supported on swift 4.1 or higher
    #if swift(>=4.1)
    public subscript<T: Codable>(key: String) -> T? {
        get {
            guard let value = state[key] else {
                return nil
            }
            if let primitive = value as? T {
                return primitive
            } else {
                guard let data = try? JSONSerialization.data(withJSONObject: value) else {
                    return nil
                }
                return try? JSONDecoder().decode(T.self, from: data)
            }
        }
        set {
            let json: Any
            guard let value = newValue else {
                state[key] = nil
                isDirty = true
                return
            }
            if let data = try? JSONEncoder().encode(value) {
                let mirror = Mirror(reflecting: value)
                switch mirror.displayStyle {
                case .collection, .enum:
                    guard let array = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
                        return
                    }
                    json = array as Any

                case .dictionary, .struct:
                    guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        return
                    }
                    json = dict as Any
                case nil:
                    json = value
                default:
                    return // ignore types we can't do anything with
                }
            } else {
                json = value
            }
            state[key] = json
            isDirty = true
        }
    }
    #endif
}




