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


internal class InMemoryStore: Store {

    private var store = [String: NSData]()

    internal func load(sessionId: String, callback: (data: NSData?, error: NSError?) -> Void) {
print("InMemoryStore: Loaded session \(sessionId)")
        callback(data: store[sessionId], error: nil)
    }

    internal func save(sessionId: String, data: NSData, callback: (error: NSError?) -> Void) {
        store[sessionId] = data
print("InMemoryStore: Stored session \(sessionId)")
        callback(error: nil)
    }

    internal func touch(sessionId: String, callback: (error: NSError?) -> Void) {
print("InMemoryStore: Touched session \(sessionId)")
        callback(error: nil)
    }

    internal func delete(sessionId: String, callback: (error: NSError?) -> Void) {
        store.removeValueForKey(sessionId)
print("InMemoryStore: Deleted session \(sessionId)")
        callback(error: nil)
    }
}
