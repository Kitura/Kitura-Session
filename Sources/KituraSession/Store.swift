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

// MARK Store

/// The protocol that defines the API for plugins that store `Session` data.
public protocol Store {
    
    /// Load the session data.
    ///
    /// - Parameter sessionId: The ID of the session.
    /// - Parameter callback: The closure to invoke once the session data is fetched.
    func load(sessionId: String, callback: @escaping (Data?, NSError?) -> Void)
    
    /// Save the session data.
    ///
    /// - Parameter sessionId: The ID of the session.
    /// - Parameter data: The data to save.
    /// - Parameter callback: The closure to invoke once the session data is saved.
    func save(sessionId: String, data: Data, callback: @escaping (NSError?) -> Void)
 
    /// Touch the session data.
    ///
    /// - Parameter sessionId: The ID of the session.
    /// - Parameter callback: The closure to invoke once the session data is touched.
    func touch(sessionId: String, callback: @escaping (NSError?) -> Void)
    
    /// Delete the session data.
    ///
    /// - Parameter sessionId: The ID of the session.
    /// - Parameter callback: The closure to invoke once the session data is deleted.
    func delete(sessionId: String, callback: @escaping (NSError?) -> Void)
}
