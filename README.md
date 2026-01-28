# SwiftSecureBytes

A Swift package for secure memory handling of sensitive data like cryptographic keys, passwords, and mnemonics. Provides automatic memory zeroing and protection against data leakage.

## Features

- **Secure Memory Management**: Automatically zeros memory when sensitive data is deallocated
- **Memory Locking**: Prevents sensitive data from being swapped to disk using `mlock`
- **Constant-Time Operations**: Prevents timing attacks through constant-time equality comparisons
- **Property Wrapper**: `@Secure` wrapper for automatic secure handling of String and Data
- **Hex Encoding**: Built-in hex string conversion for cryptographic keys
- **Collection Conformance**: Implements `RandomAccessCollection` for easy byte access

## Architecture

### Core Components

#### SecureBytes
The main class for handling sensitive byte data. It wraps `Data` and provides:
- Memory locking with `mlock()` to prevent swapping
- Automatic memory zeroing on deallocation using `memset()`
- Constant-time equality comparison
- Hex encoding/decoding
- Collection protocol conformance for array-like access

#### SecureString
A wrapper for sensitive string data (passwords, mnemonics, etc.). Internally uses `SecureBytes` for UTF-8 encoded data.

#### @Secure Property Wrapper
A property wrapper that automatically wraps `String` and `Data` values in their secure counterparts. Provides type-safe secure storage for sensitive properties.

### Security Design

- **Memory Zeroing**: Uses `memset()` to zero memory before deallocation, preventing sensitive data from remaining in RAM
- **Memory Locking**: Calls `mlock()` to pin memory pages, preventing them from being swapped to disk
- **Constant-Time Equality**: Implements timing-attack resistant comparison using XOR operations
- **No Copy-on-Write**: Avoids Swift's copy-on-write optimization for Data to ensure memory is properly zeroed

## Installation

### Swift Package Manager

Add the following to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SwiftSecureBytes.git", from: "1.0.0")
]
```

Or add it to your Xcode project via File > Add Packages.

## Usage

### Basic Usage

```swift
import SwiftSecureBytes

// Create secure bytes from data
let keyData = Data([0x01, 0x02, 0x03, 0x04])
let secureKey = SecureBytes(keyData)

// Create from hex string
if let secureKey = SecureBytes(hexString: "01020304") {
    print("Key created successfully")
}

// Access bytes safely
let bytes = secureKey.bytes // Returns Data copy
print("Key length: \(secureKey.count)")

// Convert back to hex
let hexString = secureKey.toHexString()
print("Hex: \(hexString)")
```

### Secure Strings

```swift
// Create secure string for passwords or mnemonics
let password = "my-secret-password"
let securePassword = SecureString(password)

// Access the value (creates a copy)
let plainPassword = securePassword.value
print("Password: \(plainPassword)")

// Zero memory explicitly
securePassword.zeroMemory()
```

### Property Wrapper

```swift
struct Keychain {
    @Secure var apiKey: String
    @Secure var secretData: Data
}

var keychain = Keychain(apiKey: "my-api-key", secretData: Data([0xAA, 0xBB]))

// Values are automatically secured
print(keychain.apiKey) // "my-api-key"

// Access underlying secure storage
let secureString = keychain.$apiKey as! SecureString
```

### Extensions

```swift
// Convert existing data/strings to secure types
let data = Data([1, 2, 3])
let secureData = data.toSecureBytes()

let string = "sensitive info"
let secureString = string.toSecureString()
```

### Collection Access

```swift
let secureBytes = SecureBytes([10, 20, 30, 40])

// Access individual bytes
print(secureBytes[0]) // 10
print(secureBytes[1]) // 20

// Iterate over bytes
for byte in secureBytes {
    print(byte)
}

// Check equality (constant-time)
let other = SecureBytes([10, 20, 30, 40])
print(secureBytes == other) // true
```

### Memory Management

```swift
// Memory is automatically zeroed when SecureBytes is deallocated
func processKey() {
    let key = SecureBytes(hexString: "deadbeef")!
    // Use key...
    // Memory automatically zeroed when function returns
}

// Or zero explicitly
let key = SecureBytes([1, 2, 3])
key.zeroMemory() // Zero immediately
```

## API Reference

### SecureBytes

```swift
public final class SecureBytes {
    // Initializers
    public init(_ data: Data)
    public init(_ bytes: [UInt8])
    public init(capacity: Int)
    public init?(hexString: String)
    
    // Properties
    public var bytes: Data { get }
    public var count: Int { get }
    public var isEmpty: Bool { get }
    
    // Methods
    public func zeroMemory()
    public func unsafeCopy() -> Data
    public func toHexString() -> String
    public func constantTimeEquals(_ other: SecureBytes) -> Bool
    public func constantTimeEquals(_ other: Data) -> Bool
    public func withBytes<T>(_ body: (Data) throws -> T) rethrows -> T
}

// Conforms to: Equatable, RandomAccessCollection
```

### SecureString

```swift
public final class SecureString {
    public init(_ value: String)
    
    public var value: String { get }
    public var count: Int { get }
    
    public func zeroMemory()
}
```

### @Secure Property Wrapper

```swift
@propertyWrapper
public struct Secure<Value> {
    public init(wrappedValue: Value)
    public var wrappedValue: Value { get set }
    public var projectedValue: Any { get }
}
```

### Extensions

```swift
extension String {
    public func toSecureBytes() -> SecureBytes
    public func toSecureString() -> SecureString
}

extension Data {
    public mutating func zeroBytes()
    public func toSecureBytes() -> SecureBytes
}
```

## Security Considerations

- **Memory Zeroing**: While the library attempts to zero memory, Swift's optimizer may in some cases eliminate these operations. The library uses memory barriers and `withExtendedLifetime` to mitigate this.
- **Memory Locking**: Requires appropriate system permissions. On some systems, `mlock` may fail or be limited.
- **Copy-on-Write**: When accessing `.bytes`, a copy of the data is returned. The original remains secure.
- **Thread Safety**: SecureBytes is not thread-safe. Access from multiple threads requires external synchronization.
- **Platform Support**: Memory locking may not be available on all platforms or in sandboxed environments.

## Requirements

- Swift 6.0+
- macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+

## License

[Add your license here]

## Contributing

[Add contribution guidelines]