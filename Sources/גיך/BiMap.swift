/// A collision detected when merging two BiMaps.
///
/// Describes exactly which key or value conflicts, and which tier introduced
/// the conflicting mapping. Use the `description` property for a human-readable
/// error message suitable for display in `gikh lexicon --add` or `gikh verify`.
struct BiMapCollision<Key: Hashable, Value: Hashable>: Error, CustomStringConvertible, @unchecked Sendable {
    enum Kind: @unchecked Sendable {
        /// The same key appears in both maps (forward collision).
        case duplicateKey(Key)
        /// The same value appears in both maps (reverse/bijectivity collision).
        case duplicateValue(Value)
    }

    let kind: Kind
    let sourceTier: String
    let incomingTier: String

    var description: String {
        switch kind {
        case .duplicateKey(let key):
            return """
                Collision detected: key '\(key)' is already defined in '\(sourceTier)'.
                The incoming mapping from '\(incomingTier)' introduces the same key.
                Rename the identifier in '\(incomingTier)' to resolve the conflict.
                """
        case .duplicateValue(let value):
            return """
                Collision detected: value '\(value)' is already mapped in '\(sourceTier)'.
                The incoming mapping from '\(incomingTier)' would create a non-bijective mapping.
                Choose a different Yiddish translation in '\(incomingTier)' to resolve the conflict.
                """
        }
    }
}

/// A bijective dictionary: every key maps to a unique value and vice versa.
///
/// Both `toValue` and `toKey` are O(1) average case because the reverse mapping
/// is maintained alongside the forward mapping.
struct BiMap<Key: Hashable, Value: Hashable> {
    private var forward: [Key: Value]
    private var reverse: [Value: Key]

    /// Creates a BiMap from an array of key-value pairs.
    ///
    /// - Precondition: All keys are unique **and** all values are unique.
    ///   Duplicate values would violate bijectivity and are caught with a
    ///   `precondition` failure.
    init(_ pairs: [(Key, Value)]) {
        forward = Dictionary(uniqueKeysWithValues: pairs)
        reverse = Dictionary(uniqueKeysWithValues: pairs.map { ($1, $0) })

        precondition(
            forward.count == reverse.count,
            "BiMap initialised with duplicate values — mapping is not bijective"
        )
    }

    /// Failable initialiser that returns `nil` instead of trapping when the
    /// pairs are not bijective (duplicate keys or duplicate values).
    init?(safe pairs: [(Key, Value)]) {
        // Build forward dict manually to detect duplicate keys without trapping.
        var fwd: [Key: Value] = Dictionary(minimumCapacity: pairs.count)
        for (k, v) in pairs {
            guard fwd[k] == nil else { return nil }
            fwd[k] = v
        }

        // Build reverse dict manually to detect duplicate values without trapping.
        var rev: [Value: Key] = Dictionary(minimumCapacity: pairs.count)
        for (k, v) in pairs {
            guard rev[v] == nil else { return nil }
            rev[v] = k
        }

        forward = fwd
        reverse = rev
    }

    /// Looks up the value associated with `key`.
    func toValue(_ key: Key) -> Value? { forward[key] }

    /// Looks up the key associated with `value`.
    func toKey(_ value: Value) -> Key? { reverse[value] }

    /// Merges `other` into this BiMap, enforcing bijectivity across the combined set.
    ///
    /// Returns a new BiMap containing all mappings from both maps, or throws a
    /// `BiMapCollision` describing the first conflict found. The `sourceTier` and
    /// `incomingTier` labels appear in the collision error message to identify which
    /// dictionary tiers are in conflict.
    ///
    /// - Parameters:
    ///   - other: The BiMap to merge into this one.
    ///   - sourceTier: Human-readable name for this map (e.g. "keywords").
    ///   - incomingTier: Human-readable name for the other map (e.g. "project").
    /// - Returns: A new merged BiMap.
    /// - Throws: `BiMapCollision` if any key or value in `other` collides with an
    ///   existing key or value in this map.
    func merging(
        _ other: BiMap<Key, Value>,
        sourceTier: String,
        incomingTier: String
    ) throws -> BiMap<Key, Value> {
        var merged = self

        for (key, value) in other.forward {
            // Check for key collision (same Yiddish word already defined).
            if merged.forward[key] != nil {
                throw BiMapCollision<Key, Value>(
                    kind: .duplicateKey(key),
                    sourceTier: sourceTier,
                    incomingTier: incomingTier
                )
            }
            // Check for value collision (same English word already mapped).
            if merged.reverse[value] != nil {
                throw BiMapCollision<Key, Value>(
                    kind: .duplicateValue(value),
                    sourceTier: sourceTier,
                    incomingTier: incomingTier
                )
            }
            merged.forward[key] = value
            merged.reverse[value] = key
        }

        return merged
    }
}
