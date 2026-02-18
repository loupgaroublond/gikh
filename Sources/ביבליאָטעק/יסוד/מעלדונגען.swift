import Foundation

public typealias מעלדונגן_צענטער = NotificationCenter

extension NotificationCenter {
    @_transparent public static var שותּפֿותּ: NotificationCenter { NotificationCenter.default }

    @_transparent
    public func צוהערן(
        צו נאָמען: Notification.Name,
        פֿון מקור: Any? = nil,
        אין שלאַנג: OperationQueue? = nil,
        אויספֿירן: @escaping @Sendable (Notification) -> Void
    ) -> NSObjectProtocol {
        addObserver(forName: נאָמען, object: מקור, queue: שלאַנג, using: אויספֿירן)
    }

    @_transparent
    public func פּאָסטן(_ מעלדונג: Notification.Name, פֿון מקור: Any? = nil) {
        post(name: מעלדונג, object: מקור)
    }
}

public typealias באַנוצער_שטעלונגען = UserDefaults

extension UserDefaults {
    @_transparent public static var שותּפֿותּ: UserDefaults { UserDefaults.standard }
    @_transparent public func שטעלן(_ ווערט: Any?, שליסל: String) { set(ווערט, forKey: שליסל) }
    @_transparent public func נעמען(שליסל: String) -> Any? { object(forKey: שליסל) }
    @_transparent public func נעמען_סטרינג(שליסל: String) -> String? { string(forKey: שליסל) }
    @_transparent public func נעמען_צאָל(שליסל: String) -> Int { integer(forKey: שליסל) }
    @_transparent public func נעמען_באָאָל(שליסל: String) -> Bool { bool(forKey: שליסל) }
    @_transparent public func אויסמעקן(שליסל: String) { removeObject(forKey: שליסל) }
}
