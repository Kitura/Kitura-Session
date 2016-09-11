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

// MARK CookieParameter

/// The parameters for the cookie configuration.
public enum CookieParameter {
    
    /// The cookie's name.
    case name(String)
    
    /// The cookie's Path attribute.
    case path(String)
    
    /// The cookie's Secure attribute.
    case secure(Bool)
    
    /// The cookie's Max-Age attribute.
    case maxAge(TimeInterval)
}
