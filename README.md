<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/IBM-Swift/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>


<p align="center">
    <a href="https://ibm-swift.github.io/Kitura-Session/index.html">
    <img src="https://img.shields.io/badge/apidoc-KituraSession-1FBCE4.svg?style=flat" alt="APIDoc">
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
A pluggable framework for managing user sessions in a Swift server using Kitura.

## Swift version
The latest version of Kitura-Session requires **Swift 4.0** or later. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.

## Usage

#### Add dependencies

Add the `Kitura-Session` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `Kitura-Session` [release](https://github.com/IBM-Swift/Kitura-Session/releases).

```swift
.package(url: "https://github.com/IBM-Swift/Kitura-Session.git", from: "x.x.x")
```

Add `KituraSession` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["KituraSession"]),
```

#### Import package

```swift
import KituraSession
```

## Raw routing Session

#### Getting Started

In order to use the Session middleware on a Raw route, an instance of `Session` has to be created:
```swift
public init(secret: String, cookie: [CookieParameter]?=nil, store: Store?=nil)
```
**Where:**
   - *secret* is a String to be used for session encoding. It should be a large unguessable string, a minimum of 14 characters long.
   - *cookie* is a list of options for session's cookies. The options are (as specified in the `CookieParameter` enumeration):
     - `name` - cookie's name, defaults to "kitura-session-id".
     - `path` - cookie's path attribute, this defines the path for which this cookie should be supplied. Defaults to "/" which means allow any path.
     - `secure` - cookie's secure attribute, this indicates whwether the cookie should be provided only over secure (https) connections. Defaults to false.
     - `maxAge` - cookie's maxAge attribute, that is, the maximum age (in seconds) from the time of issue that the cookie should be kept for. Defaults to -1.0, i.e. no expiration.
   - *store* is an instance of a plugin for a session backing store that implements the `Store` protocol. If not set, `InMemoryStore` is used.
   <br>

   The *cookie* and *store* parameters are optional.

   The *secret* parameter is used to secure the session ID and ensure that the session ID cannot be guessed. *Secret* is used to derive a pair of encryption and signature keys via PBKDF2 and a fixed IV to make the session ID cookie be authenticated and encrypted. *Secret* isn't used directly to encrypt or compute the MAC of the cookie.

#### Example

In this example, an instance of `RedisStore` is created that will be used to persist session data (see [`KituraSessionRedis`](https://github.com/IBM-Swift/Kitura-Session-Redis) for more information).  An instance of `Session` is then created, specifying *redisStore* as the session store.  Finally, the *session* instance is registered as a middleware on the desired path.

```swift
import Kitura
import KituraSession
import KituraSessionRedis

let redisStore = RedisStore(redisHost: host, redisPort: port)
let session = Session(secret: "Some secret", store: redisStore)
router.all(middleware: session)
```

#### Storing Any in a session

Within your Kitura routes, you can store `Any` type inside the `request.session` for a given key. This can then be retrieved as an `Any` and cast to the required type:

```swift
router.post("/session") {request, response, next in
    request.session?["key"] = "value"
    next()
}
router.get("/session") {request, response, next in
    let value = request.session?["key"] as? String
    next()
}
```

This `Any` type must be JSON serializable, otherwise the session will fail when it attempts to save the session.

#### Storing Codable in a Session

Available from **Swift 4.1** or later

Within your Kitura routes, you can also store `Codable` objects inside the `request.session` for a given key. This can then be retrieved as the declared type:

```swift
public struct User: Codable {
    let name: String
}
router.post("/user") { request, response, next in
    let user = User(name: "Kitura")
    request.session?["User"] = user
    next()
}
router.get("/user") { request, response, next in
    let user: User? = request.session?["Kitura"]
    next()
}
```

## TypeSafeSession Example

To use sessions on a Codable route, declare a type that conforms to the TypeSafeSession protocol:

```swift
// Defines the session instance data
final class MySession: TypeSafeSession {
    let sessionId: String                       // Requirement: every session must have an ID
    var books: [Book]                           // User-defined type, where Book conforms to Codable

    init(sessionId: String) {                   // Requirement: must be able to create a new (empty)
        self.sessionId = sessionId              // session containing just an ID. Assign a default or
        books = []                              // empty value for any non-optional properties.
    }
}

// Defines the configuration of the user's type: how the cookie is constructed, and how the session is persisted.
extension MySession {
    static let sessionCookie: SessionCookie = SessionCookie(name: "MySession", secret: "Top Secret")
    static var store: Store?
}
```

The MySession type can then be included in the application's Codable route handlers. For example:

```swift
struct Book: Codable {
    let title: String
    let author: String
}

router.get("/cart") { (session: MySession, respondWith: ([Book]?, RequestError?) -> Void) in
    respondWith(session.books, nil)
}

router.post("/cart") { (session: MySession, book: Book, respondWith: (Book?, RequestError) -> Void) in
    var session = session       // Required when mutating a Struct
    session.books.append(book)
    session.save()
    respondWith(book, nil)
}

```
## Plugins

* [Redis store](https://github.com/IBM-Swift/Kitura-Session-Redis)
* [SQL store using Kuery](https://github.com/krzyzanowskim/Kitura-Session-Kuery) (community authored)

## API Documentation
For more information visit our [API reference](https://ibm-swift.github.io/Kitura-Session/index.html).

## Community

We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
