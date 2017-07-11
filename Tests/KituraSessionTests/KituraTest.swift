/**
 * Copyright IBM Corporation 2016, 2017
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

import XCTest

@testable import KituraNet

import Foundation
import Dispatch

protocol KituraTest {}

extension KituraTest {

    func doTearDown() {
        //  sleep(10)
    }

    func performServerTest(router: ServerDelegate, asyncTasks: @escaping () -> Void...) {
        do {
            let server = try HTTPServer.listen(on: 8090, delegate: router)
            let requestQueue = DispatchQueue(label: "Request queue")

            for asyncTask in asyncTasks {
                requestQueue.async(execute: asyncTask)
            }

            requestQueue.sync {
                // blocks test until request completes
                server.stop()
            }
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func performRequest(method: String, path: String, callback: @escaping ClientRequest.Callback, headers: [String: String]? = nil, requestModifier: ((ClientRequest) -> Void)? = nil) {
        var allHeaders = [String: String]()
        if  let headers = headers {
            for  (headerName, headerValue) in headers {
                allHeaders[headerName] = headerValue
            }
        }
        allHeaders["Content-Type"] = "text/plain"
        let options: [ClientRequest.Options] =
                [.method(method), .hostname("localhost"), .port(8090), .path(path), .headers(allHeaders)]
        let req = HTTP.request(options, callback: callback)
        if let requestModifier = requestModifier {
            requestModifier(req)
        }
        req.end()
    }
}
