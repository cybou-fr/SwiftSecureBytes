# SwiftSecureBytes

[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-blue.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/your-org/SwiftSecureBytes/actions)

A Swift package for secure memory handling of sensitive data like cryptographic keys, passwords, and mnemonics. Provides automatic memory zeroing and protection against data leakage.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Security Considerations](#security-considerations)
- [Requirements](#requirements)
- [Changelog](#changelog)
- [Contributing](#contributing)
- [Authors](#authors)
- [License](#license)
- [Support](#support)
- [Roadmap](#roadmap)

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

## Quick Start

```swift
import SwiftSecureBytes

// Secure your cryptographic key
let key = SecureBytes(hexString: "deadbeefcafebabe")!

// Use it safely - memory is automatically zeroed when done
print("Key length: \(key.count)") // Key length: 8
```

## Installation

### Swift Package Manager

Add the following to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/cybou-fr/SwiftSecureBytes.git", from: "1.0.0")
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

## Testing

Run the test suite to ensure everything works correctly:

```bash
swift test
```

The test suite covers:
- SecureBytes creation and memory management
- Constant-time equality operations
- Property wrapper functionality
- Collection protocol conformance
- Memory locking behavior
- Hex encoding/decoding

## Security Considerations

- **Memory Zeroing**: While the library attempts to zero memory, Swift's optimizer may in some cases eliminate these operations. The library uses memory barriers and `withExtendedLifetime` to mitigate this.
- **Memory Locking**: Requires appropriate system permissions. On some systems, `mlock` may fail or be limited.
- **Copy-on-Write**: When accessing `.bytes`, a copy of the data is returned. The original remains secure.
- **Thread Safety**: SecureBytes is not thread-safe. Access from multiple threads requires external synchronization.
- **Platform Support**: Memory locking may not be available on all platforms or in sandboxed environments.

## Requirements

- macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+

## Changelog

### Version 1.0.0
- Initial release
- SecureBytes class with memory locking and zeroing
- SecureString class for sensitive string data
- @Secure property wrapper
- Hex encoding/decoding support
- Collection protocol conformance
- Constant-time equality operations

## Contributing

We welcome contributions! Please follow these guidelines:

### Development Setup
1. Fork the repository
2. Clone your fork: `git clone https://github.com/cybou-fr/SwiftSecureBytes.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Run tests: `swift test`
6. Ensure code compiles: `swift build`
7. Commit your changes: `git commit -am 'Add some feature'`
8. Push to the branch: `git push origin feature/your-feature-name`
9. Create a Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use clear, descriptive names
- Add documentation comments for public APIs
- Write tests for new functionality
- Ensure all tests pass before submitting

### Reporting Issues
- Use GitHub Issues to report bugs
- Include Swift version, platform, and steps to reproduce
- For security issues, please email maintainers directly

## Authors

- **CybBackup Team** - Initial development and maintenance

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 CybBackup Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Support

- **Issues**: [GitHub Issues](https://github.com/cybou-fr/SwiftSecureBytes/issues)
- **Discussions**: [GitHub Discussions](https://github.com/cybou-fr/SwiftSecureBytes/discussions)
- **Documentation**: This README and inline code documentation

For security-related questions or concerns, please contact the maintainers directly.

## Roadmap

### Planned Features
- [ ] Additional cryptographic utilities
- [ ] Key derivation function wrappers
- [ ] Hardware security module integration
- [ ] Performance optimizations
- [ ] Additional platform support

### Future Considerations
- Cross-platform memory locking improvements
- Advanced secure data structures
- Integration with Swift Crypto framework