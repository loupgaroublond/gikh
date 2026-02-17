// BiMap.swift
// GikhCore — A bidirectional dictionary enforcing bijectivity.

import Foundation

/// A bijective (one-to-one) mapping between keys and values.
///
/// Both `Key -> Value` and `Value -> Key` lookups are O(1).
/// Insertions that would violate bijectivity (duplicate key or duplicate value) throw.
public struct BiMap<Key: Hashable, Value: Hashable>: Sendable
    where Key: Sendable, Value: Sendable
{
    private var forward: [Key: Value]
    private var reverse: [Value: Key]

    // MARK: - Initializers

    /// Creates an empty BiMap.
    public init() {
        forward = [:]
        reverse = [:]
    }

    /// Creates a BiMap from an array of key-value pairs.
    ///
    /// - Precondition: All keys must be unique and all values must be unique
    ///   (the mapping must be bijective).
    public init(_ pairs: [(Key, Value)]) {
        forward = Dictionary(uniqueKeysWithValues: pairs)
        reverse = Dictionary(uniqueKeysWithValues: pairs.map { ($1, $0) })
        precondition(
            forward.count == reverse.count,
            "Mapping is not bijective — duplicate values detected"
        )
    }

    /// Creates a BiMap from a `Dictionary`, verifying bijectivity.
    ///
    /// - Precondition: All values in the dictionary must be unique.
    public init(uniqueKeysWithValues dictionary: [Key: Value]) {
        forward = dictionary
        reverse = Dictionary(uniqueKeysWithValues: dictionary.map { ($0.value, $0.key) })
        precondition(
            forward.count == reverse.count,
            "Mapping is not bijective — duplicate values detected"
        )
    }

    // MARK: - Lookups

    /// Returns the value associated with the given key, or `nil` if the key is not present.
    public func toValue(_ key: Key) -> Value? { forward[key] }

    /// Returns the key associated with the given value, or `nil` if the value is not present.
    public func toKey(_ value: Value) -> Key? { reverse[value] }

    /// Returns `true` if the key is present in the forward mapping.
    public func containsKey(_ key: Key) -> Bool { forward[key] != nil }

    /// Returns `true` if the value is present in the reverse mapping.
    public func containsValue(_ value: Value) -> Bool { reverse[value] != nil }

    // MARK: - Properties

    /// The number of key-value pairs in the BiMap.
    public var count: Int { forward.count }

    /// Whether the BiMap contains no entries.
    public var isEmpty: Bool { forward.isEmpty }

    /// All key-value pairs as an array of tuples.
    public var allPairs: [(Key, Value)] {
        forward.map { ($0.key, $0.value) }
    }

    /// All keys in the BiMap.
    public var keys: Dictionary<Key, Value>.Keys { forward.keys }

    /// All values in the BiMap.
    public var values: Dictionary<Key, Value>.Values { forward.values }

    // MARK: - Mutation

    /// Inserts a key-value pair, throwing if either the key or value already exists.
    public mutating func insert(_ key: Key, _ value: Value) throws {
        if let existing = forward[key] {
            throw BiMapError.duplicateKey(
                description: "Key already maps to \(existing)"
            )
        }
        if let existing = reverse[value] {
            throw BiMapError.duplicateValue(
                description: "Value already maps from \(existing)"
            )
        }
        forward[key] = value
        reverse[value] = key
    }

    /// Returns a new BiMap containing all pairs from both `self` and `other`.
    ///
    /// Throws if any key or value from `other` conflicts with an existing entry in `self`.
    public func merged(with other: BiMap<Key, Value>) throws -> BiMap<Key, Value> {
        var result = self
        for (key, value) in other.forward {
            try result.insert(key, value)
        }
        return result
    }

    /// Removes the pair for the given key, returning the associated value if it existed.
    @discardableResult
    public mutating func removeKey(_ key: Key) -> Value? {
        guard let value = forward.removeValue(forKey: key) else { return nil }
        reverse.removeValue(forKey: value)
        return value
    }

    /// Removes the pair for the given value, returning the associated key if it existed.
    @discardableResult
    public mutating func removeValue(_ value: Value) -> Key? {
        guard let key = reverse.removeValue(forKey: value) else { return nil }
        forward.removeValue(forKey: key)
        return key
    }
}

// MARK: - Errors

/// Errors thrown when a BiMap insertion would violate bijectivity.
public enum BiMapError: Error, LocalizedError {
    /// A key already exists in the forward mapping.
    case duplicateKey(description: String)
    /// A value already exists in the reverse mapping.
    case duplicateValue(description: String)

    public var errorDescription: String? {
        switch self {
        case .duplicateKey(let desc): return desc
        case .duplicateValue(let desc): return desc
        }
    }
}

// MARK: - Codable for BiMap<String, String>

extension BiMap: Codable where Key == String, Value == String {

    /// Encodes as an array of `{"key": "value"}` objects to preserve ordering intent.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let pairs = forward.map { ["\($0.key)": "\($0.value)"] }
        try container.encode(pairs)
    }

    /// Decodes from an array of single-entry dictionaries.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let pairs = try container.decode([[String: String]].self)

        var fwd: [String: String] = [:]
        var rev: [String: String] = [:]

        for pair in pairs {
            guard let key = pair.keys.first, let value = pair.values.first else {
                continue
            }
            fwd[key] = value
            rev[value] = key
        }

        precondition(
            fwd.count == rev.count,
            "Decoded mapping is not bijective — duplicate values detected"
        )

        forward = fwd
        reverse = rev
    }
}
