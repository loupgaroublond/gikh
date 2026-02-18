import SwiftData
import Foundation

// MARK: - Core SwiftData type aliases
// Note: @Model and #Predicate are macros and cannot be typealiased.
// They must be used directly in source code.
// The transpiler keyword dictionary maps Yiddish macro names to these.

public typealias מאָדעל_באַהעלטעניש = ModelContainer
public typealias מאָדעל_קאָנטעקסט = ModelContext
public typealias ברענג_באַשרײַבונג = FetchDescriptor
public typealias סאָרטיר_באַשרײַבונג = SortDescriptor
public typealias מאָדעל_קאָנפֿיגוראַציע = ModelConfiguration
public typealias מאָדעל_שעמע = Schema

// MARK: - ModelContainer convenience initializer
extension ModelContainer {
    @_alwaysEmitIntoClient
    public static func מיט_טיפּן(
        _ טיפּן: [any PersistentModel.Type],
        קאָנפֿיגוראַציע: ModelConfiguration = ModelConfiguration()
    ) throws -> ModelContainer {
        try ModelContainer(for: Schema(טיפּן), configurations: [קאָנפֿיגוראַציע])
    }
}

// MARK: - ModelContext convenience methods
extension ModelContext {
    @_transparent
    public func אײַנפֿיגן<T: PersistentModel>(_ מאָדעל: T) {
        self.insert(מאָדעל)
    }

    @_transparent
    public func אויסמעקן<T: PersistentModel>(_ מאָדעל: T) {
        self.delete(מאָדעל)
    }

    @_alwaysEmitIntoClient
    public func אָפּהיטן() throws {
        try self.save()
    }

    @_alwaysEmitIntoClient
    public func ברענגען<T: PersistentModel>(_ באַשרײַבונג: FetchDescriptor<T>) throws -> [T] {
        try self.fetch(באַשרײַבונג)
    }
}

// MARK: - SortOrder typealias
public typealias סאָרטיר_סדר = SortOrder

extension SortOrder {
    public static var פֿאָרויס: SortOrder { .forward }
    public static var צוריקוואַרטס: SortOrder { .reverse }
}

// MARK: - ModelConfiguration convenience
extension ModelConfiguration {
    @_alwaysEmitIntoClient
    public init(
        נאָמען: String? = nil,
        נאָר_אין_זיכאָרן: Bool = false
    ) {
        if let נ = נאָמען {
            self.init(נ, isStoredInMemoryOnly: נאָר_אין_זיכאָרן)
        } else {
            self.init(isStoredInMemoryOnly: נאָר_אין_זיכאָרן)
        }
    }
}

// MARK: - Schema convenience
extension Schema {
    @_alwaysEmitIntoClient
    public static func מיט_טיפּן(_ טיפּן: [any PersistentModel.Type]) -> Schema {
        Schema(טיפּן)
    }
}
