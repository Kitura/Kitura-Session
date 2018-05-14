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


public final class InMemoryStore: Store {

    private var store = [String: Data]()

    public func load(sessionId: String, callback: @escaping (Data?, NSError?) -> Void) {
        callback(store[sessionId], nil)
    }

    public func save(sessionId: String, data: Data, callback: @escaping (NSError?) -> Void) {
        store[sessionId] = data
        callback(nil)
    }

    public func touch(sessionId: String, callback: @escaping (NSError?) -> Void) {
        callback(nil)
    }

    public func delete(sessionId: String, callback: @escaping (NSError?) -> Void) {
        store.removeValue(forKey: sessionId)
        callback(nil)
    }
    
    public init() {
        
    }
}
