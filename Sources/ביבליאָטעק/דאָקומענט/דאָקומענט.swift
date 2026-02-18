import AppKit
import Foundation

// MARK: - Document-based app typealiases
public typealias דאָקומענט = NSDocument
public typealias פֿענצטער_קאָנטראָלער = NSWindowController
public typealias טיילער_בליק_קאָנטראָלער = NSSplitViewController
public typealias טיילער_בליק = NSSplitView
public typealias גליד_בליק = NSOutlineView
public typealias טעקסט_בליק = NSTextView
public typealias בלעטל_בליק = NSScrollView
public typealias טאַבעלע_בליק = NSTableView
public typealias בליק = NSView
public typealias פֿענצטער = NSWindow
public typealias בליק_קאָנטראָלער = NSViewController

// MARK: - NSSplitViewItem
public typealias טיילער_בליק_פּונקט = NSSplitViewItem

extension NSSplitViewItem {
    @_alwaysEmitIntoClient
    public static func זײַטן_שטאַנגע(
        _ קאָנטראָלער: NSViewController
    ) -> NSSplitViewItem {
        NSSplitViewItem(sidebarWithViewController: קאָנטראָלער)
    }

    @_alwaysEmitIntoClient
    public static func אינהאַלט(
        _ קאָנטראָלער: NSViewController
    ) -> NSSplitViewItem {
        NSSplitViewItem(contentListWithViewController: קאָנטראָלער)
    }

    @_alwaysEmitIntoClient
    public static func נאָרמאַל(
        _ קאָנטראָלער: NSViewController
    ) -> NSSplitViewItem {
        NSSplitViewItem(viewController: קאָנטראָלער)
    }
}

// MARK: - NSTextStorage / NSLayoutManager (for syntax highlighting)
public typealias טעקסט_ספּײַכלער = NSTextStorage
public typealias אויסלייג_פֿאַרוואַלטער = NSLayoutManager
public typealias טעקסט_באַהעלטעניש = NSTextContainer

// MARK: - NSAttributedString helpers for syntax highlighting
public typealias צוגעשריבענע_סטרינג = NSAttributedString
public typealias באַרעכנבאַרע_צוגעשריבענע_סטרינג = NSMutableAttributedString

extension NSMutableAttributedString {
    @_alwaysEmitIntoClient
    public func שטעלן_פֿאַרב(
        _ פֿאַרב: NSColor,
        פֿון אָנהייב: Int,
        לענג: Int
    ) {
        self.addAttribute(
            .foregroundColor,
            value: פֿאַרב,
            range: NSRange(location: אָנהייב, length: לענג)
        )
    }

    @_alwaysEmitIntoClient
    public func שטעלן_שריפֿט(
        _ שריפֿט: NSFont,
        פֿון אָנהייב: Int,
        לענג: Int
    ) {
        self.addAttribute(
            .font,
            value: שריפֿט,
            range: NSRange(location: אָנהייב, length: לענג)
        )
    }
}

// MARK: - NSColor Yiddish names
extension NSColor {
    @_transparent public static var רויט: NSColor { .red }
    @_transparent public static var בלוי: NSColor { .blue }
    @_transparent public static var גרין: NSColor { .green }
    @_transparent public static var ווײַס: NSColor { .white }
    @_transparent public static var שוואַרץ: NSColor { .black }
    @_transparent public static var גרוי: NSColor { .gray }
    @_transparent public static var געל: NSColor { .yellow }
    @_transparent public static var אָראַנזש: NSColor { .orange }
    @_transparent public static var לילאַ: NSColor { .purple }
    @_transparent public static var ראָזע: NSColor { .systemPink }
    @_transparent public static var כּתּום: NSColor { .orange }
    @_transparent public static var הויפּט_שריפֿט_פֿאַרב: NSColor { .labelColor }
    @_transparent public static var צווייטע_שריפֿט_פֿאַרב: NSColor { .secondaryLabelColor }
    @_transparent public static var אונטערלייג_פֿאַרב: NSColor { .windowBackgroundColor }
}

// MARK: - NSFont helpers
extension NSFont {
    @_alwaysEmitIntoClient
    public static func מאָנאָ_שריפֿט(גרייס: CGFloat) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: גרייס, weight: .regular)
    }

    @_alwaysEmitIntoClient
    public static func סיסטעם_שריפֿט(גרייס: CGFloat) -> NSFont {
        NSFont.systemFont(ofSize: גרייס)
    }
}

// MARK: - NSOutlineView delegate/datasource helpers
public typealias גליד_בליק_דעלעגאַט = NSOutlineViewDelegate
public typealias גליד_בליק_דאַטן_קוואַל = NSOutlineViewDataSource

// MARK: - Toolbar
public typealias וואָרקזייג_שטאַנגע = NSToolbar
public typealias וואָרקזייג_פּונקט = NSToolbarItem

// MARK: - File management helpers
extension NSDocument {
    @_alwaysEmitIntoClient
    public func לייענען_טעקסט(פֿון אַדרעס: URL) throws -> String {
        try String(contentsOf: אַדרעס, encoding: .utf8)
    }
}

// MARK: - Application entry
public typealias אַפּליקאַציע = NSApplication
public typealias אַפּליקאַציע_דעלעגאַט = NSApplicationDelegate
