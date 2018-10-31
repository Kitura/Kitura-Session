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
public struct SessionCodingError: Equatable, Hashable, Error, CustomStringConvertible {
    public var description: String
    
    
    // MARK: Creating a SessionCodingError
    
    /**
     Creates an error representing the given error reason string.
     - parameter reason: A human-readable description of the error code.
     */
    public init(description: String) {
        self.description = description
    }
    
    /// Thrown when the provided Key is not found in the session.
    public static func keyNotFound(key: String) -> SessionCodingError {
        return SessionCodingError(description: "keyNotFound: \(key)")
    }
    
    /// Thrown when a primitive Decodable or array of primitive Decodables fails to be cast to the provided type.
    public static let failedPrimitiveCast = SessionCodingError(description: "failedPrimitiveCast")
    
    /// Throw when the provided Encodable fails to be serialized to JSON.
    public static let failedToSerializeJSON = SessionCodingError(description: "failedToSerializeJSON")
}
