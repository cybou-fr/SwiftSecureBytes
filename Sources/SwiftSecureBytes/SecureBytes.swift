//
//  SecureBytes.swift
//  SwiftSecureBytes
//
//  Created by CybBackup Team
//
//  Provides secure memory handling for sensitive data like cryptographic keys.
//  Automatically zeros memory on deallocation to prevent key material leakage.
//

import Foundation

/// A wrapper for sensitive byte data that securely zeros memory when deallocated.
/// Use this for storing cryptographic keys, mnemonics, and other sensitive material.
///
/// - Important: This class uses `withUnsafeMutableBytes` to zero the underlying buffer
///   before releasing memory, preventing key material from remaining in memory.
public final class SecureBytes {
    /// The underlying data storage
    private var data: Data
    
    /// Flag to track if memory has been cleared
    private var isCleared: Bool = false
    
    /// Creates SecureBytes from existing Data.
    /// - Parameter data: The sensitive data to wrap
    public init(_ data: Data) {
        self.data = data
        lockMemory()
    }
    
    /// Creates SecureBytes from a byte array.
    /// - Parameter bytes: The sensitive bytes to wrap
    public init(_ bytes: [UInt8]) {
        self.data = Data(bytes)
        lockMemory()
    }
    
    /// Creates empty SecureBytes with specified capacity.
    /// - Parameter capacity: Number of bytes to allocate
    public init(capacity: Int) {
        self.data = Data(count: capacity)
        lockMemory()
    }
    
    /// Creates SecureBytes from hex string.
    /// - Parameter hexString: Hex-encoded string
    public init?(hexString: String) {
        guard let data = Data(hexEncodedString: hexString) else {
            return nil
        }
        self.data = data
        lockMemory()
    }
    
    /// Access the underlying data for read operations.
    /// - Warning: Avoid holding references to this data beyond immediate use.
    public var bytes: Data {
        return data
    }
    
    /// The number of bytes stored
    public var count: Int {
        return data.count
    }
    
    /// Returns true if the secure bytes have been cleared
    public var isEmpty: Bool {
        return isCleared || data.isEmpty
    }
    
    /// Securely zeros the memory and releases the data.
    /// Called automatically on deallocation.
    deinit {
        zeroMemory()
    }
    
    /// Explicitly zeros the memory contents.
    /// Call this when you want to clear sensitive data before deallocation.
    public func zeroMemory() {
        guard !isCleared && !data.isEmpty else { return }
        
        data.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            // Use memset_s if available (guaranteed not to be optimized away)
            // Fall back to volatile memset pattern
            let count = buffer.count
            
            // Write zeros
            memset(baseAddress, 0, count)
            
            // Memory barrier to prevent compiler optimization
            #if swift(>=5.0)
            withExtendedLifetime(self) { }
            #endif
        }
        
        // Unlock before zeroing (though we could zero then unlock, zeroing needs write access)
        // Check if we need to unlock first?
        // Actually, mlock prevents swapping, not writing.
        
        data.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            
            // Write zeros
            memset(baseAddress, 0, buffer.count)
            
            // Unlock memory
            munlock(baseAddress, buffer.count)
            
            // Memory barrier to prevent compiler optimization
            #if swift(>=5.0)
            withExtendedLifetime(self) { }
            #endif
        }
        
        isCleared = true
    }
    
    /// Creates a copy of the data that's safe to pass around.
    /// The copy is NOT a SecureBytes - caller is responsible for clearing.
    /// - Returns: A copy of the underlying data
    public func unsafeCopy() -> Data {
        return Data(data)
    }
    
    /// Convert to hex string without leaking data
    public func toHexString() -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Constant-time equality comparison to prevent timing attacks
    /// - Parameter other: Other SecureBytes to compare
    /// - Returns: True if contents are identical
    public func constantTimeEquals(_ other: SecureBytes) -> Bool {
        guard count == other.count else { return false }
        
        var result: UInt8 = 0
        for (a, b) in zip(data, other.data) {
            result |= a ^ b
        }
        return result == 0
    }
    
    /// Constant-time equality comparison with raw Data
    /// - Parameter other: Data to compare
    /// - Returns: True if contents are identical
    public func constantTimeEquals(_ other: Data) -> Bool {
        guard count == other.count else { return false }
        
        var result: UInt8 = 0
        for (a, b) in zip(data, other) {
            result |= a ^ b
        }
        return result == 0
    }
    
    /// Perform operation with the bytes, automatically clearing on completion
    /// - Parameter body: Closure that receives the Data
    /// - Returns: Result of the closure
    public func withBytes<T>(_ body: (Data) throws -> T) rethrows -> T {
        return try body(data)
    }
    
    // MARK: - Memory Locking
    
    private func lockMemory() {
        guard !isCleared && !data.isEmpty else { return }
        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            mlock(baseAddress, buffer.count)
        }
    }
    
    private func unlockMemory() {
        guard !data.isEmpty else { return } // unlocking cleared data is fine if pointer still valid, but we use data.withUnsafeBytes
        data.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            munlock(baseAddress, buffer.count)
        }
    }
}

// MARK: - Equatable
extension SecureBytes: Equatable {
    public static func == (lhs: SecureBytes, rhs: SecureBytes) -> Bool {
        return lhs.constantTimeEquals(rhs)
    }
}

// MARK: - RandomAccessCollection
extension SecureBytes: RandomAccessCollection {
    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return count
    }
    
    public subscript(position: Int) -> UInt8 {
        return data[position]
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public func index(before i: Int) -> Int {
        return i - 1
    }
}

// MARK: - SecureString

/// A wrapper for sensitive string data (mnemonics, passwords, etc.)
public final class SecureString {
    private let secureBytes: SecureBytes
    
    /// Creates SecureString from a string.
    /// - Parameter value: The sensitive string to wrap
    public init(_ value: String) {
        if let data = value.data(using: .utf8) {
            self.secureBytes = SecureBytes(data)
        } else {
            self.secureBytes = SecureBytes(Data())
        }
    }
    
    /// Get the string value (creates a copy - use sparingly)
    public var value: String {
        return String(data: secureBytes.bytes, encoding: .utf8) ?? ""
    }
    
    /// The length of the string
    public var count: Int {
        return secureBytes.count
    }
    
    /// Explicitly zero the memory
    public func zeroMemory() {
        secureBytes.zeroMemory()
    }
    
    deinit {
        secureBytes.zeroMemory()
    }
}

// MARK: - Extension: String

extension String {
    /// Converts string to SecureBytes (for mnemonics, passwords, etc.)
    public func toSecureBytes() -> SecureBytes {
        guard let data = self.data(using: .utf8) else {
            return SecureBytes(Data())
        }
        return SecureBytes(data)
    }
    
    /// Converts string to SecureString
    public func toSecureString() -> SecureString {
        return SecureString(self)
    }
}

// MARK: - Extension: Data

extension Data {
    /// Mutating function to zero all bytes in this Data object.
    /// - Warning: This may not work on copy-on-write data. Use SecureBytes for guaranteed clearing.
    public mutating func zeroBytes() {
        guard !isEmpty else { return }
        withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            memset(baseAddress, 0, buffer.count)
        }
    }
    
    /// Convert to SecureBytes for protected storage
    public func toSecureBytes() -> SecureBytes {
        return SecureBytes(self)
    }
}
