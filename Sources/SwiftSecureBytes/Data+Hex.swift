//
//  Data+Hex.swift
//  SwiftSecureBytes
//
//  Internal extensions for hex encoding/decoding.
//

import Foundation

extension Data {
    /// Converts the data to a lowercase hexadecimal string representation
    internal func hexEncodedString() -> String {
        return map { String(format: "%02x", $0) }.joined()
    }

    /// Creates Data from a hex-encoded string
    internal init?(hexEncodedString: String) {
        let hexString = hexEncodedString.replacingOccurrences(of: " ", with: "").lowercased()
        guard hexString.count % 2 == 0 else { return nil }

        var data = Data()
        var index = hexString.startIndex

        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }

        self = data
    }
}
