# Kitura-Session
A pluggable framework for managing user sessions in a Swift server using Kitura

[![Build Status - Master](https://travis-ci.org/IBM-Swift/Kitura.svg?branch=master)](https://travis-ci.org/IBM-Swift/Kitura-Session)
![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Summary
A pluggable framework for managing user sessions in a Swift server using Kitura

## Table of Contents
* [Swift version](#swift-version)
* [API](#api)
* [Example](#example)
* [Plugins](#plugins)
* [License](#license)

## Swift version
The latest version of Kitura-Session works with the DEVELOPMENT-SNAPSHOT-2016-07-25-a version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.


## API
In order to use Session middleware, an instance of `Session` has to created:
```swift
public init(secret: String, cookie: [CookieParameter]?=nil, store: Store?=nil)
```
**Where:**
   - *secret* is a String to be used for session encoding.
   - *cookie* is a list of options for session's cookies. The options are (specified in `CookieParameter` enumeration): `name` - cookie's name, defaults to "kitura-session-id", `path` - cookie's Path attribute defaults to "/", `secure` - cookie's Secure attribute, false by default, and `maxAge` - an NSTimeInterval with cookie's expiration time in seconds, defaults to -1.0, i.e., no expiration.
   - *store* is an instance of a plugin for session backing store that implements `Store` protocol. If not set, `InMemoryStore` is used.
   <br>

   The last two parameters are optional.

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

## Plugins

* [Redis store](https://github.com/IBM-Swift/Kitura-Session-Redis)

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
