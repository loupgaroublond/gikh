@_transparent
public func דרוק(_ זאַכן: Any..., טרענער: String = " ", סוף: String = "\n") {
    print(זאַכן.map { "\($0)" }.joined(separator: טרענער), terminator: סוף)
}

@_transparent
public func מין<T: Comparable>(_ אַ: T, _ ב: T) -> T { Swift.min(אַ, ב) }

@_transparent
public func מאַקס<T: Comparable>(_ אַ: T, _ ב: T) -> T { Swift.max(אַ, ב) }

@_transparent
public func אַבס<T: Comparable & SignedNumeric>(_ צאָל: T) -> T { Swift.abs(צאָל) }

@_transparent
public func שרײַבן(_ מעלדונג: String = "") { print(מעלדונג) }

// Fatal error — cannot be @_transparent because it is a diverging function
@_alwaysEmitIntoClient
public func קריטישער_פֿעלער(
    _ מעלדונג: @autoclosure () -> String = String(),
    טעקע: StaticString = #file,
    שורה: UInt = #line
) -> Never {
    fatalError(מעלדונג(), file: טעקע, line: שורה)
}

// Precondition — cannot be @_transparent (diverging path)
@_alwaysEmitIntoClient
public func פֿאַרזיכערונג(
    _ צושטאַנד: @autoclosure () -> Bool,
    _ מעלדונג: @autoclosure () -> String = String(),
    טעקע: StaticString = #file,
    שורה: UInt = #line
) {
    precondition(צושטאַנד(), מעלדונג(), file: טעקע, line: שורה)
}

// Assert — cannot be @_transparent (diverging path in debug)
@_alwaysEmitIntoClient
public func טעסטירן(
    _ צושטאַנד: @autoclosure () -> Bool,
    _ מעלדונג: @autoclosure () -> String = String(),
    טעקע: StaticString = #file,
    שורה: UInt = #line
) {
    assert(צושטאַנד(), מעלדונג(), file: טעקע, line: שורה)
}
