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


import KituraNet
import Foundation
import XCTest
#if swift(>=4.1)
  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif
#endif

class CookieUtils {

    static func cookieFrom(response: ClientResponse, named: String) -> (HTTPCookie?, String?) {
        var resultCookie: HTTPCookie? = nil
        var resultExpire: String?
        for (headerKey, headerValues) in response.headers {
            let lowercaseHeaderKey = headerKey.lowercased()
            if  lowercaseHeaderKey  ==  "set-cookie" {
                for headerValue in headerValues {
                    let parts = headerValue.components(separatedBy: "; ")
                    let nameValue = parts[0].components(separatedBy: "=")
                    XCTAssertEqual(nameValue.count, 2, "Malformed Set-Cookie header \(headerValue)")

                    if  nameValue[0] == named {
                        #if os(Linux)
                            var properties = [HTTPCookiePropertyKey: Any]()
                            properties[HTTPCookiePropertyKey.name]  =  nameValue[0]
                            properties[HTTPCookiePropertyKey.value] =  nameValue[1]

                            for  part in parts[1..<parts.count] {
                                var pieces = part.components(separatedBy: "=")
                                let piece = pieces[0].lowercased()
                                switch(piece) {
                                case "secure", "httponly":
                                    properties[HTTPCookiePropertyKey.secure] = "Yes"
                                case "path" where pieces.count == 2:
                                    properties[HTTPCookiePropertyKey.path] = pieces[1]
                                case "domain" where pieces.count == 2:
                                    properties[HTTPCookiePropertyKey.domain] = pieces[1]
                                case "expires" where pieces.count == 2:
                                    resultExpire = pieces[1]
                                default:
                                    XCTFail("Malformed Set-Cookie header \(headerValue)")
                                }
                            }
                        #else
                            var properties = [HTTPCookiePropertyKey: AnyObject]()

                            properties[HTTPCookiePropertyKey.name]  =  nameValue[0] as NSString
                            properties[HTTPCookiePropertyKey.value] =  nameValue[1] as NSString

                            for  part in parts[1..<parts.count] {
                                let pieces = part.components(separatedBy: "=")
                                let piece = pieces[0].lowercased()
                                switch(piece) {
                                case "secure", "httponly":
                                    properties[HTTPCookiePropertyKey.secure] = "Yes" as NSString
                                case "path" where pieces.count == 2:
                                    properties[HTTPCookiePropertyKey.path] = pieces[1] as NSString
                                case "domain" where pieces.count == 2:
                                    properties[HTTPCookiePropertyKey.domain] = pieces[1] as NSString
                                case "expires" where pieces.count == 2:
                                    resultExpire = pieces[1]
                                default:
                                    XCTFail("Malformed Set-Cookie header \(headerValue)")
                                }
                            }
                        #endif

                        XCTAssertNotNil(properties[HTTPCookiePropertyKey.domain], "Malformed Set-Cookie header \(headerValue)")
                        resultCookie = HTTPCookie(properties: properties)

                       break
                    }
                }
            }
        }

        return (resultCookie, resultExpire)
    }

}
