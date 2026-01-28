//
//  Secure.swift
//  SwiftSecureBytes
//
//  Created by CybBackup Team
//
//  Property Wrapper for automatic secure handling.
//

import Foundation

/// A property wrapper that invalidates the stored value when it's no longer needed.
/// Automatically wraps String or Data into SecureString or SecureBytes.
@propertyWrapper
public struct Secure<Value> {
    private var storage: Any?
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public var wrappedValue: Value {
        get {
            if let secureStr = storage as? SecureString, let val = secureStr.value as? Value {
                return val
            }
            if let secureBytes = storage as? SecureBytes, let val = secureBytes.bytes as? Value {
                // Warning: This returns a copy of Data if Value is Data, not strictly correct for reference types logic 
                // but Value is generic.
                return val
            }
            if let secureBytes = storage as? SecureBytes, let val = secureBytes.unsafeCopy() as? Value {
                 return val 
            }
            
            // Fallback (shouldn't happen if constrained properly or init handles it)
            fatalError("Secure wrapper used with unsupported type or internal error")
        }
        set {
            if let str = newValue as? String {
                storage = SecureString(str)
            } else if let data = newValue as? Data {
                storage = SecureBytes(data)
            } else {
                fatalError("@Secure only supports String and Data")
            }
        }
    }
    
    /// Access to the underlying secure storage
    public var projectedValue: Any {
        return storage ?? ()
    }
}
