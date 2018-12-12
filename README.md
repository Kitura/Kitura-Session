<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="http://www.kitura.io/">
    <img src="https://img.shields.io/badge/docs-kitura.io-1FBCE4.svg" alt="Docs">
    </a>
    <a href="https://travis-ci.org/IBM-Swift/Kitura-Session">
    <img src="https://travis-ci.org/IBM-Swift/Kitura-Session.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# Kitura-Session
A pluggable framework for managing user sessions in a Swift server using Kitura

## Summary
A pluggable framework for managing user sessions in a Swift server using Kitura

## Table of Contents
* [Swift version](#swift-version)
* [API](#api)
* [Example](#example)
* [Plugins](#plugins)
* [License](#license)

## Swift version
The latest version of Kitura-Session requires **Swift 4.0** or later. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.


## API
In order to use the Session middleware, an instance of `Session` has to be created:
```swift
public init(secret: String, cookie: [CookieParameter]?=nil, store: Store?=nil)
```
**Where:**
   - *secret* is a String to be used for session encoding. It should be a large unguessable string, say minimum 14 characters long.
   - *cookie* is a list of options for session's cookies. The options are (specified in `CookieParameter` enumeration): `name` - cookie's name, defaults to "kitura-session-id", `path` - cookie's Path attribute defaults to "/", `secure` - cookie's Secure attribute, false by default, and `maxAge` - an NSTimeInterval with cookie's expiration time in seconds, defaults to -1.0, i.e., no expiration.
   - *store* is an instance of a plugin for session backing store that implements `Store` protocol. If not set, `InMemoryStore` is used.
   <br>

   The last two parameters are optional.

   <br>
   The *secret* parameter is used to secure the session ID and ensure that the session ID cannot be guessed. *Secret* is used to derive a pair of encryption and signature keys via PBKDF2 and a fixed IV to make the session ID cookie be authenticated encrypted. *Secret* isn't used directly to encrypt or compute the MAC of the cookie.

## Example

This is an example of `Session` middleware with [`KituraSessionRedis`](https://github.com/IBM-Swift/Kitura-Session-Redis) plugin:

```swift
import KituraSession
import KituraSessionRedis

let redisStore = RedisStore(redisHost: host, redisPort: port)
let session = Session(secret: "Some secret", store: redisStore)
router.all(middleware: session)
```
First an instance of `RedisStore` is created (see [`KituraSessionRedis`](https://github.com/IBM-Swift/Kitura-Session-Redis) for more information), then an instance of `Session` with the store as parameter is created, and finally it is connected to the desired path.

## Codable Session Example

The example below defines a `User` struct and a `Router` with the sessions middleware.  
The router has a POST route that decodes a `User` instance from the request body
     and stores it in the request session using the user's id as the key.  
The router has a GET route that reads a user id from the query parameters
     and decodes the instance of `User` that is in the session for that id.  

```
public struct User: Codable {
        let id: String
        let name: String
}
let router = Router()
router.all(middleware: Session(secret: "secret"))
router.post("/user") { request, response, next in
         let user = try request.read(as: User.self)
         request.session?[user.id] = user
         response.status(.created)
         response.send(user)
         next()
}
router.get("/user") { request, response, next in
         guard let userID = request.queryParameters["userid"] else {
            return try response.status(.notFound).end()
         }
         guard let user: User = request.session?[userID] else {
            return try response.status(.internalServerError).end()
         }
         response.status(.OK)
         response.send(user)
         next()
}
```
## Plugins

* [Redis store](https://github.com/IBM-Swift/Kitura-Session-Redis)
* [SQL store using Kuery](https://github.com/krzyzanowskim/Kitura-Session-Kuery) (community authored)

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
