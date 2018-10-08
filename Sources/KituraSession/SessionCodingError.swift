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

// MARK StoreError

/// An error indicating the failure of an operation to encode/decode into/from the session `Store`.
public enum SessionCodingError: Swift.Error {
    
     //Thrown when the provided Key is not found in the session.
    case keyNotFound(key: String)
    
    //Thrown when a primative Decodable or array of primative Decodables fails to be cast to the provided type.
    case failedPrimativeCast()
    
    //Throw when the provided Encodable fails to be serialized to JSON.
    case failedToSerializeJSON()
}
