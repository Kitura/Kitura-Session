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
import SwiftyJSON

// MARK SessionState

#if os(Linux)
typealias SessionStateObjectType = Any
#else
typealias SessionStateObjectType = AnyObject
#endif

/// A set of helper functions to manipulate session data.
public class SessionState {

    /// The session ID.
    public let id: String

    /// Dirty flag
    internal private(set) var isDirty = false

    /// Empty flag
    internal var isEmpty: Bool { return state.isEmpty }

    /// Actual session state
    private var state: JSON

    /// Store for session state
    private let store: Store

    internal init(id: String, store: Store) {
        self.id = id
        self.store = store
        state = JSON([String: SessionStateObjectType]() as SessionStateObjectType)
    }

    /// Reload the session data from the session `Store`.
    ///
    /// - Parameter callback: The closure to invoke once the reading of session data is complete.
    public func reload(callback: @escaping (NSError?) -> Void) {
        store.load(sessionId: id) {(data: Data?, error: NSError?) in
            if  error == nil {
                if  let data = data {
                    self.state = JSON(data: data, options: [])
                } else {
                    // Not found in store
                    self.state = JSON([String: SessionStateObjectType]() as SessionStateObjectType)
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
            let data = try state.rawData()
            store.save(sessionId: id, data: data, callback: callback)
        } catch(let error as NSError) {
            callback(error)
        } catch {
            callback(nil)
        }
    }

    /// Delete the session data from the session `Store`.
    ///
    /// - Parameter callback: The closure to invoke once the deletion of session data is complete.
    public func destroy(callback: @escaping (NSError?) -> Void) {
        store.delete(sessionId: id) { error in
            self.state = JSON([String: SessionStateObjectType]() as SessionStateObjectType)
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
    public subscript(key: String) -> JSON {
        get {
            return state[key]
        }
        set {
            state[key] = newValue
            isDirty = true
        }
    }
}
