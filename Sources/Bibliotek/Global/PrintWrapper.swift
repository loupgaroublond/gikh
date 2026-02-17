@_transparent
public func דרוק(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
}
