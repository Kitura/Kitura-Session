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


#if os(Linux)
    func unbox(_ code: Any) -> Codable? {
        return code as? Codable
    }
#else
    public func unbox(_ array: NSArray) -> [Codable]? {
        var result = [Codable]()
        for val in array {
            result.append(unbox(val))
        }
        return result
    }
    
    public func unbox(_ dict: NSDictionary) -> [String: Codable]? {
        var result = [String: Codable]()
        for (key, value) in dict {
            if let key = key as? String {
                result[key] = unbox(value)
            }
        }
        return result
    }
    
    public func unbox(_ str: NSString) -> Codable? {
        return (str as String) as Codable
    }
    
    public func unbox(_ num: NSNumber) -> Codable? {
        let codableNum : Codable
        if floor(num.doubleValue) == num.doubleValue {
            codableNum = num.doubleValue
        } else {
            codableNum = num.intValue
        }
        return codableNum
    }
    
    public func unbox<T: Any>(_ val: T) -> Codable? {
        let unboxed: Codable?
        switch val {
        case let str as NSString: unboxed = unbox(str)
        case let arr as NSArray:  unboxed = unbox(arr)
        case let dict as NSDictionary: unboxed = unbox(dict)
        case let num as NSNumber: unboxed = unbox(num)
        case is NSNull: unboxed = nil
        default: unboxed = nil
        }
        return unboxed
    }
#endif

