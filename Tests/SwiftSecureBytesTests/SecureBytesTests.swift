//
//  SecureBytesTests.swift
//  SwiftSecureBytesTests
//
//  Tests for SecureBytes and SecureString.
//

import XCTest
@testable import SwiftSecureBytes

class SecureBytesTests: XCTestCase {
    
    // MARK: - SecureBytes Tests
    
    func testSecureStringCreation() {
        let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let secureString = SecureString(mnemonic)
        
        XCTAssertEqual(secureString.value, mnemonic)
        XCTAssertGreaterThan(secureString.count, 0)
    }
    
    func testSecureStringZeroing() {
        let secret = "sensitive password"
        let secureString = SecureString(secret)
        
        XCTAssertEqual(secureString.value, secret)
        
        secureString.zeroMemory()
        // After zeroing, the internal data should be cleared
    }
    
    func testSecureBytesConstantTimeEquals() {
        let data1 = Data("test data".utf8)
        let data2 = Data("test data".utf8)
        let data3 = Data("different".utf8)
        
        let secure1 = SecureBytes(data1)
        let secure2 = SecureBytes(data2)
        let secure3 = SecureBytes(data3)
        
        XCTAssertTrue(secure1.constantTimeEquals(secure2))
        XCTAssertFalse(secure1.constantTimeEquals(secure3))
    }
    
    func testSecureBytesHexConversion() {
        let originalHex = "0123456789abcdef"
        
        guard let secureBytes = SecureBytes(hexString: originalHex) else {
            XCTFail("Failed to create SecureBytes from hex")
            return
        }
        
        let convertedHex = secureBytes.toHexString()
        XCTAssertEqual(convertedHex, originalHex)
    }
    
    // MARK: - Conformance Tests
    
    func testEquatable() {
        let bytes1 = SecureBytes([1, 2, 3])
        let bytes2 = SecureBytes([1, 2, 3])
        let bytes3 = SecureBytes([1, 2, 4])
        
        XCTAssertEqual(bytes1, bytes2)
        XCTAssertNotEqual(bytes1, bytes3)
        XCTAssertTrue(bytes1 == bytes2)
    }
    
    func testCollectionConformance() {
        let secure = SecureBytes([10, 20, 30])
        
        XCTAssertEqual(secure.count, 3)
        XCTAssertEqual(secure[0], 10)
        XCTAssertEqual(secure[1], 20)
        XCTAssertEqual(secure[2], 30)
        
        // Test iterator
        var sum = 0
        for byte in secure {
            sum += Int(byte)
        }
        XCTAssertEqual(sum, 60)
    }
    
    // MARK: - Property Wrapper Tests
    
    struct MockKeychain {
        @Secure var apiKey: String
        @Secure var secretData: Data
    }
    
    func testPropertyWrapper() {
        let key = "my-secret-key"
        let data = Data([0xAA, 0xBB])
        
        var keychain = MockKeychain(apiKey: key, secretData: data)
        
        // Test getter
        XCTAssertEqual(keychain.apiKey, key)
        XCTAssertEqual(keychain.secretData, data)
        
        // Test setter
        keychain.apiKey = "new-key"
        XCTAssertEqual(keychain.apiKey, "new-key")
        
        // Test underlying type
        XCTAssertTrue(keychain.$apiKey is SecureString)
        XCTAssertTrue(keychain.$secretData is SecureBytes)
    }
    
    // MARK: - Memory Locking Tests
    
    func testMemoryLockingDoesNotCrash() {
        // We can't easily verify locking without root or complex checks,
        // but we can ensure the calls are made and don't crash the app.
        let secure = SecureBytes([1, 2, 3, 4, 5])
        
        // Force a zeroing which triggers munlock
        secure.zeroMemory()
        
        XCTAssertTrue(secure.isEmpty)
    }
}
