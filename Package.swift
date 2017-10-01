// swift-tools-version:4.0

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

import PackageDescription

let package = Package(
    name: "Kitura-Session",
    products: [
        .library(name: "KituraSession", targets: ["KituraSession"])
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "1.7.0"),
        .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", from: "0.8.0")
    ],
    targets: [
        .target(name: "KituraSession", dependencies: ["Kitura", "Cryptor"]),
        .testTarget(name: "KituraSessionTests", dependencies: ["KituraSession"])
    ]
)
