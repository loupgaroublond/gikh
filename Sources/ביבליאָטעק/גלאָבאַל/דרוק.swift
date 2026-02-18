@_transparent
public func דרוק(_ זאַכן: Any..., טרענער: String = " ", סוף: String = "\n") {
    print(זאַכן.map { "\($0)" }.joined(separator: טרענער), terminator: סוף)
}
