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


import Cryptor
import KituraSys
import LoggerAPI

import Foundation

///
/// Cookie encoding and decoding
///
class CookieCryptography {
    
    ///
    /// Key for encryption (AES-128)
    ///
    private var encryptonKey : [UInt8]
    ///
    /// Key for signature (HMAC-SHA-256)
    ///
    private var signatureKey : [UInt8]
    ///
    /// Length of cookie value before padding
    ///
    private let originalLength = 36
    
    init (secret: String) {
        var salt : [UInt8]
        do {
            salt = try Random.generate(byteCount: 16)
        }
        catch {
            salt = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
        }
        let keyLength = UInt(Cryptor.Algorithm.aes.defaultKeySize)
        self.encryptonKey = PBKDF.deriveKey(fromPassword: secret, salt: salt, prf: .sha256, rounds: 2, derivedKeyLength: keyLength)
        
        do {
            salt = try Random.generate(byteCount: 16)
        }
        catch {
            salt = [15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0]
        }
        self.signatureKey = PBKDF.deriveKey(fromPassword: secret, salt: salt, prf: .sha256, rounds: 2, derivedKeyLength: keyLength)
    }
    
    ///
    /// Return iv.encrypted.hmac, where iv is random initialization vector 16 bytes long, encrypted is the input encrypted 
    /// with AES-128, hmac is the signature created with HMAC-SHA-256.
    /// 
    func encode (_ plain: String) -> String? {
        // Encryption
        let iv : [UInt8]
        do {
            iv = try Random.generate(byteCount: 16)
        } catch {
            Log.error("Error generating random bytes for cookie encoding")
            return nil
        }
        
        let plainData = CryptoUtils.byteArray(from: plain)
        var dataToCipher = plainData
        // Padding
        if plainData.count % Cryptor.Algorithm.aes.blockSize != 0 {
            dataToCipher = CryptoUtils.zeroPad(byteArray: plainData, blockSize: Cryptor.Algorithm.aes.blockSize)
        }

        guard let cipherData = Cryptor(operation: .encrypt, algorithm: .aes, options: .none, key: encryptonKey, iv: iv).update(byteArray: dataToCipher)?.final() else {
            Log.error("Failed to encrypt cookie")
            return nil
        }
        let cipherText = CryptoUtils.hexString(from: cipherData)
        
        // HMAC
        guard let hmacData = HMAC(using: HMAC.Algorithm.sha256, key: signatureKey).update(byteArray: cipherData)?.final() else {
            Log.error("Failed to sign cookie")
            return nil
        }
        let hmac = CryptoUtils.hexString(from: hmacData)
        
        // iv.encryptedData.hmac
        return CryptoUtils.hexString(from: iv) + "." + cipherText + "." + hmac
    }
    
    ///
    /// Decode the input iv.encryptedData.hmac by comparing hmac with expected signature and decrypting the data.
    ///
    func decode (_ encoded: String) -> String? {
        let encodedArray = encoded.components(separatedBy: ".")
        guard encodedArray.count == 3 else {
            Log.error("Wrong number of components, \(encodedArray.count), in encoded cookie")
            return nil
        }
        
        let iv = CryptoUtils.byteArray(fromHex: encodedArray[0])
        let cipherData = CryptoUtils.byteArray(fromHex: encodedArray[1])
        let hmac = CryptoUtils.byteArray(fromHex: encodedArray[2])
        
        guard iv.count == 16 else {
            Log.error("Wrong iv length in cookie decoding")
            return nil
        }
        
        guard let expectedHmac = HMAC(using: HMAC.Algorithm.sha256, key: signatureKey).update(byteArray: cipherData)?.final() else {
            Log.error("Failed to create expected signiture in cookie decoding")
            return nil
        }
        
        guard hmac == expectedHmac else {
            Log.error("HMAC doesn't match expected HMAC in cookie decoding")
            return nil
        }
        
        // Decryption
        guard let decryptedData = Cryptor(operation: .decrypt, algorithm: .aes, options: .none, key: encryptonKey, iv: iv).update(byteArray: cipherData)?.final() else {
            Log.error("Failed to decrypt cookie")
            return nil
        }
        
        var resultData = decryptedData
        // Remove padding
        resultData.removeSubrange(originalLength ..< decryptedData.count)
        return StringUtils.fromUtf8String(CryptoUtils.data(from: resultData))!
    }
    
}