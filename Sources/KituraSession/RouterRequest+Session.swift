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

import Foundation

// MARK RouterRequest+SessionState
private let SESSION_USER_INFO_KEY = "@@Kitura@@Session@@"

/// Extension of the `RouterRequest` class that provides access to the session's state
/// that is stored in a `SessionState` object.
public extension RouterRequest {
    
    /// The session's state that is stored in a `SessionState` object.
    public internal(set) var session: SessionState? {
        get {
            return userInfo[SESSION_USER_INFO_KEY] as? SessionState
        }
        set {
            userInfo[SESSION_USER_INFO_KEY] = newValue
        }
    }
}
