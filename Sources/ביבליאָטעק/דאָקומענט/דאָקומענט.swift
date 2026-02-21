@_exported import AppKit
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
public typealias אַפּק_בליק = NSView
public typealias פֿענצטער = NSWindow
public typealias בליק_קאָנטראָלער = NSViewController
public typealias יסוד_אָביעקט = NSObject
public typealias אַפּק_מעניו = NSMenu
public typealias מעניו_פּונקט = NSMenuItem
public typealias טאַבעלע_קאָלאָנקע = NSTableColumn
public typealias טאַבעלע_זעל = NSTableCellView
public typealias אַפּק_טעקסט_פֿעלד = NSTextField
public typealias בליק_קענציכן = NSUserInterfaceItemIdentifier
public typealias אויסלייג_באַגרענעצונג = NSLayoutConstraint
public typealias בערײַך = NSRange
public typealias מעלדונג = Notification
public typealias קאָדירער = NSCoder

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

    @_transparent public var מינימאַלע_דיקייט: CGFloat {
        get { minimumThickness }
        set { minimumThickness = newValue }
    }
    @_transparent public var מאַקסימאַלע_דיקייט: CGFloat {
        get { maximumThickness }
        set { maximumThickness = newValue }
    }
    @_transparent public var באַפֿאָרצוגטע_דיקייט: CGFloat {
        get { preferredThicknessFraction }
        set { preferredThicknessFraction = newValue }
    }
    @_transparent public var קען_צונויפֿפֿאַלן: Bool {
        get { canCollapse }
        set { canCollapse = newValue }
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

    @_alwaysEmitIntoClient
    public func שטעלן_צוגעשריבענע_סטרינג(_ צוגעשריבענע: NSAttributedString) {
        setAttributedString(צוגעשריבענע)
    }
}

// MARK: - NSFont / NSColor type aliases
public typealias אַפּק_שריפֿט = NSFont
public typealias אַפּק_פֿאַרב = NSColor

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
    @_transparent public static var טעקסט_הינטערגרונט: NSColor { .textBackgroundColor }
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

    @_transparent public var טעקע_אַדרעס: URL? { fileURL }

    @_alwaysEmitIntoClient
    public func צוגעבן_פֿענצטער_קאָנטראָלער(_ קאָנטראָלער: NSWindowController) {
        addWindowController(קאָנטראָלער)
    }
}

// MARK: - Application entry
public typealias אַפּליקאַציע = NSApplication
public typealias אַפּליקאַציע_דעלעגאַט = NSApplicationDelegate

// MARK: - NSView
extension NSView {
    @_transparent public var אויטאָ_אויסלייג: Bool {
        get { translatesAutoresizingMaskIntoConstraints }
        set { translatesAutoresizingMaskIntoConstraints = newValue }
    }

    @_alwaysEmitIntoClient
    public func צוגעבן_אונטערבליק(_ בליק: NSView) {
        addSubview(בליק)
    }

    @_transparent public var איז_באַהאַלטן: Bool {
        get { isHidden }
        set { isHidden = newValue }
    }
}

// MARK: - NSView.AutoresizingMask
extension NSView.AutoresizingMask {
    @_transparent public static var ברייט: NSView.AutoresizingMask { .width }
    @_transparent public static var הייך: NSView.AutoresizingMask { .height }
}

// MARK: - NSScrollView
extension NSScrollView {
    @_transparent public var האָט_ווערטיקאַלן_בלעטערער: Bool {
        get { hasVerticalScroller }
        set { hasVerticalScroller = newValue }
    }
    @_transparent public var האָט_האָריזאָנטאַלן_בלעטערער: Bool {
        get { hasHorizontalScroller }
        set { hasHorizontalScroller = newValue }
    }
    @_transparent public var אויטאָ_באַהאַלט_בלעטערער: Bool {
        get { autohidesScrollers }
        set { autohidesScrollers = newValue }
    }
    @_transparent public var דאָקומענט_בליק: NSView? {
        get { documentView }
        set { documentView = newValue }
    }
}

// MARK: - NSOutlineView
extension NSOutlineView {
    @_transparent public var דאַטן_קוואַל: NSOutlineViewDataSource? {
        get { dataSource }
        set { dataSource = newValue }
    }
    @_transparent public var דעלעגאַט_ג: NSOutlineViewDelegate? {
        get { delegate }
        set { delegate = newValue }
    }
    @_transparent public var אויטאָ_גרייס_גליד: Bool {
        get { autoresizesOutlineColumn }
        set { autoresizesOutlineColumn = newValue }
    }
    @_transparent public var אײַנרוק_פּער_שטופֿע: CGFloat {
        get { indentationPerLevel }
        set { indentationPerLevel = newValue }
    }
    @_transparent public var שורה_הייך: CGFloat {
        get { rowHeight }
        set { rowHeight = newValue }
    }
    @_alwaysEmitIntoClient
    public func צוגעבן_קאָלאָנקע(_ קאָלאָנקע: NSTableColumn) {
        addTableColumn(קאָלאָנקע)
    }
    @_transparent public var גליד_קאָלאָנקע: NSTableColumn? {
        get { outlineTableColumn }
        set { outlineTableColumn = newValue }
    }
    @_transparent public var ציל: AnyObject? {
        get { target }
        set { target = newValue }
    }
    @_transparent public var אַקציע: Selector? {
        get { action }
        set { action = newValue }
    }
    @_alwaysEmitIntoClient
    public func לאָדן_דאַטן_פֿריש() { reloadData() }

    @_alwaysEmitIntoClient
    public func אויפֿמאַכן(_ אינטעם: Any?, קינדער: Bool = false) {
        expandItem(אינטעם, expandChildren: קינדער)
    }

    @_transparent public var אויסגעקליבטע_שורה: Int { selectedRow }

    @_alwaysEmitIntoClient
    public func אינטעם(אין שורה: Int) -> Any? { item(atRow: שורה) }
}

// MARK: - NSTextView
extension NSTextView {
    @_transparent public var איז_רעדאַקטירבאַר: Bool {
        get { isEditable }
        set { isEditable = newValue }
    }
    @_transparent public var איז_אויסקלײַבבאַר: Bool {
        get { isSelectable }
        set { isSelectable = newValue }
    }
    @_transparent public var איז_רײַך_טעקסט: Bool {
        get { isRichText }
        set { isRichText = newValue }
    }
    @_transparent public var באַנוצט_שריפֿט_טאַוול: Bool {
        get { usesFontPanel }
        set { usesFontPanel = newValue }
    }
    @_transparent public var הינטערגרונט_פֿאַרב: NSColor {
        get { backgroundColor }
        set { backgroundColor = newValue }
    }
    @_transparent public var טעקסט_אַרײַנשטופּ: NSSize {
        get { textContainerInset }
        set { textContainerInset = newValue }
    }
    @_transparent public var גרונט_שרײַב_ריכטונג: NSWritingDirection {
        get { baseWritingDirection }
        set { baseWritingDirection = newValue }
    }
    @_transparent public var איז_ווערטיקאַל_ענדערלעך: Bool {
        get { isVerticallyResizable }
        set { isVerticallyResizable = newValue }
    }
    @_transparent public var איז_האָריזאָנטאַל_ענדערלעך: Bool {
        get { isHorizontallyResizable }
        set { isHorizontallyResizable = newValue }
    }
}

// MARK: - NSTextContainer
extension NSTextContainer {
    @_transparent public var ברייט_פֿאָלגט_בליק: Bool {
        get { widthTracksTextView }
        set { widthTracksTextView = newValue }
    }
}

// MARK: - NSWindow
extension NSWindow {
    @_transparent public var טיטל_ט: String {
        get { title }
        set { title = newValue }
    }
    @_transparent public var דורכזיכטיקע_טיטל_שטאַנגע: Bool {
        get { titlebarAppearsTransparent }
        set { titlebarAppearsTransparent = newValue }
    }
    @_alwaysEmitIntoClient
    public func צענטרירן() { center() }

    @_transparent public var אינהאַלט_קאָנטראָלער: NSViewController? {
        get { contentViewController }
        set { contentViewController = newValue }
    }
    @_alwaysEmitIntoClient
    public func מאַכן_הויפּט() { makeKeyAndOrderFront(nil) }
}

// MARK: - NSWindow.StyleMask
extension NSWindow.StyleMask {
    @_transparent public static var מיט_טיטל: NSWindow.StyleMask { .titled }
    @_transparent public static var שליסבאַר: NSWindow.StyleMask { .closable }
    @_transparent public static var פֿאַרקלענערבאַר: NSWindow.StyleMask { .miniaturizable }
    @_transparent public static var ענדערבאַר: NSWindow.StyleMask { .resizable }
    @_transparent public static var פֿולע_גרייס: NSWindow.StyleMask { .fullSizeContentView }
}

// MARK: - NSWindowController
extension NSWindowController {
    @_transparent public var פֿענצטער_רעף: NSWindow? { window }
}

// MARK: - NSMenu
extension NSMenu {
    @_alwaysEmitIntoClient
    public func צוגעבן_פּונקט(_ פּונקט: NSMenuItem) { addItem(פּונקט) }
}

// MARK: - NSMenuItem
extension NSMenuItem {
    @_alwaysEmitIntoClient
    public static func טרענער() -> NSMenuItem { separator() }

    @_transparent public var אונטער_מעניו: NSMenu? {
        get { submenu }
        set { submenu = newValue }
    }
}

// MARK: - NSTableColumn
extension NSTableColumn {
    @_transparent public var טיטל_ט: String {
        get { title }
        set { title = newValue }
    }
    @_transparent public var ברייט: CGFloat {
        get { width }
        set { width = newValue }
    }
}

// MARK: - NSTableCellView
extension NSTableCellView {
    @_transparent public var טעקסט_רעף: NSTextField? { textField }
}

// MARK: - NSTextField
extension NSTextField {
    @_transparent public var סטרינג_ווערט: String {
        get { stringValue }
        set { stringValue = newValue }
    }
    @_transparent public var שריפֿט_פֿאַרב: NSColor? {
        get { textColor }
        set { textColor = newValue }
    }
    @_transparent public var שריפֿט: NSFont? {
        get { font }
        set { font = newValue }
    }
    @_transparent public var אויסריכטונג: NSTextAlignment {
        get { alignment }
        set { alignment = newValue }
    }
}

// MARK: - NSLayoutConstraint
extension NSLayoutConstraint {
    @_alwaysEmitIntoClient
    public static func אַקטיווירן(_ באַגרענעצונגען: [NSLayoutConstraint]) {
        NSLayoutConstraint.activate(באַגרענעצונגען)
    }
}

// MARK: - NSApplication
extension NSApplication {
    @_transparent public static var שותּפֿותּ_אַפּ: NSApplication { shared }

    @_alwaysEmitIntoClient
    public func לויפֿן() { run() }

    @_transparent public var דעלעגאַט_אַפּ: NSApplicationDelegate? {
        get { delegate }
        set { delegate = newValue }
    }
    @_transparent public var הויפּט_מעניו: NSMenu? {
        get { mainMenu }
        set { mainMenu = newValue }
    }
}

// MARK: - NSWritingDirection
extension NSWritingDirection {
    @_transparent public static var רעכטס_צו_לינקס: NSWritingDirection { .rightToLeft }
    @_transparent public static var לינקס_צו_רעכטס: NSWritingDirection { .leftToRight }
}

// MARK: - NSTextAlignment
extension NSTextAlignment {
    @_transparent public static var רעכטס: NSTextAlignment { .right }
    @_transparent public static var לינקס: NSTextAlignment { .left }
    @_transparent public static var צענטער: NSTextAlignment { .center }
}

// MARK: - NSSplitView
extension NSSplitView {
    @_transparent public var איז_ווערטיקאַל: Bool {
        get { isVertical }
        set { isVertical = newValue }
    }
}

// MARK: - NSSplitView.DividerStyle
extension NSSplitView.DividerStyle {
    @_transparent public static var דין: NSSplitView.DividerStyle { .thin }
}

// MARK: - NSSplitViewController
extension NSSplitViewController {
    @_alwaysEmitIntoClient
    public func צוגעבן_טיילער(_ פּונקט: NSSplitViewItem) {
        addSplitViewItem(פּונקט)
    }
}

// MARK: - NSRange
extension NSRange {
    @_alwaysEmitIntoClient
    public init(אָרט: Int, לענג: Int) {
        self.init(location: אָרט, length: לענג)
    }
}

// MARK: - NSView anchor wrappers
extension NSView {
    @_transparent public var אויבן_אַנקער: NSLayoutYAxisAnchor { topAnchor }
    @_transparent public var אונטן_אַנקער: NSLayoutYAxisAnchor { bottomAnchor }
    @_transparent public var אָנהייב_אַנקער: NSLayoutXAxisAnchor { leadingAnchor }
    @_transparent public var סוף_אַנקער: NSLayoutXAxisAnchor { trailingAnchor }
    @_transparent public var מיטן_אַרויף_אַנקער: NSLayoutYAxisAnchor { centerYAnchor }
    @_transparent public var מיטן_זײַט_אַנקער: NSLayoutXAxisAnchor { centerXAnchor }

    @_transparent public var קענציכן: NSUserInterfaceItemIdentifier? {
        get { identifier }
        set { identifier = newValue }
    }
}

extension NSLayoutXAxisAnchor {
    @_alwaysEmitIntoClient
    public func באַגרענעצונג(צו אַנקער: NSLayoutXAxisAnchor) -> NSLayoutConstraint {
        constraint(equalTo: אַנקער)
    }
    @_alwaysEmitIntoClient
    public func באַגרענעצונג(צו אַנקער: NSLayoutXAxisAnchor, פּלוס: CGFloat) -> NSLayoutConstraint {
        constraint(equalTo: אַנקער, constant: פּלוס)
    }
}

extension NSLayoutYAxisAnchor {
    @_alwaysEmitIntoClient
    public func באַגרענעצונג(צו אַנקער: NSLayoutYAxisAnchor) -> NSLayoutConstraint {
        constraint(equalTo: אַנקער)
    }
    @_alwaysEmitIntoClient
    public func באַגרענעצונג(צו אַנקער: NSLayoutYAxisAnchor, פּלוס: CGFloat) -> NSLayoutConstraint {
        constraint(equalTo: אַנקער, constant: פּלוס)
    }
}

// MARK: - NSTextField factory init
extension NSTextField {
    @_alwaysEmitIntoClient
    public static func לאַבל(_ טעקסט: String) -> NSTextField {
        NSTextField(labelWithString: טעקסט)
    }
}

// MARK: - NSViewController
extension NSViewController {
    @_transparent public var איז_בליק_געלאָדן: Bool { isViewLoaded }
}

// MARK: - URL directory check
extension URL {
    @_transparent public var איז_סדר_וועג: Bool { hasDirectoryPath }
}

// MARK: - NSMenu init wrapper
extension NSMenu {
    @_alwaysEmitIntoClient
    public convenience init(טיטל: String) {
        self.init(title: טיטל)
    }
}

// MARK: - NSMenuItem init wrapper
extension NSMenuItem {
    @_alwaysEmitIntoClient
    public convenience init(טיטל: String, אַקציע: Selector?, שליסל: String = "") {
        self.init(title: טיטל, action: אַקציע, keyEquivalent: שליסל)
    }
}

// MARK: - NSWindow convenience init
extension NSWindow {
    @_alwaysEmitIntoClient
    public convenience init(אינהאַלט: NSRect, סטיל: NSWindow.StyleMask, באַפֿערונג: NSWindow.BackingStoreType = .buffered, אָפּשטעלן: Bool = false) {
        self.init(contentRect: אינהאַלט, styleMask: סטיל, backing: באַפֿערונג, defer: אָפּשטעלן)
    }
}

// MARK: - NSWindow.BackingStoreType
extension NSWindow.BackingStoreType {
    @_transparent public static var באַפֿערט: NSWindow.BackingStoreType { .buffered }
}

// MARK: - NSWindowController document property
extension NSWindowController {
    @_transparent public var דאָקומענט_רעף: AnyObject? {
        get { document }
        set { document = newValue }
    }
}

// MARK: - NSViewController view property
extension NSViewController {
    @_transparent public var בליק_רעף: NSView {
        get { view }
        set { view = newValue }
    }
}

// MARK: - NSSplitViewController properties
extension NSSplitViewController {
    @_transparent public var טיילער_בליק_רעף: NSSplitView { splitView }
}

// MARK: - NSSplitView.DividerStyle
extension NSSplitView {
    @_transparent public var טיילער_סטיל: NSSplitView.DividerStyle {
        get { dividerStyle }
        set { dividerStyle = newValue }
    }
}

// MARK: - NSTextView additional properties
extension NSTextView {
    @_transparent public var גרייס_מאַסקע: NSView.AutoresizingMask {
        get { autoresizingMask }
        set { autoresizingMask = newValue }
    }
    @_transparent public var טעקסט_באַהעלטעניש_רעף: NSTextContainer? { textContainer }
    @_transparent public var טעקסט_ספּײַכלער_רעף: NSTextStorage? { textStorage }
    @_transparent public var שריפֿט: NSFont? {
        get { font }
        set { font = newValue }
    }
}

// MARK: - NSOutlineView makeView wrapper
extension NSOutlineView {
    @_alwaysEmitIntoClient
    public func מאַכן_בליק(קענציכן: NSUserInterfaceItemIdentifier, אייגנטימער: Any?) -> NSView? {
        makeView(withIdentifier: קענציכן, owner: אייגנטימער)
    }
}

// MARK: - NSAttributedString.Key Yiddish names
extension NSAttributedString.Key {
    @_transparent public static var שריפֿט_מפֿתח: NSAttributedString.Key { .font }
    @_transparent public static var פֿאָרגרונט_פֿאַרב_מפֿתח: NSAttributedString.Key { .foregroundColor }
}

// MARK: - NSError helpers
public typealias אַפּק_טעות = NSError

extension NSError {
    @_alwaysEmitIntoClient
    public static func קאָקאָאַ_טעות(קאָד: Int) -> NSError {
        NSError(domain: NSCocoaErrorDomain, code: קאָד)
    }
}

public let טעקע_שרײַב_אומבאַוואוסט_טעות: Int = NSFileWriteUnknownError

// MARK: - FileManager additional wrappers
extension FileManager {
    @_alwaysEmitIntoClient
    public func אינהאַלט_פֿון_סדר(
        בײַ וועג: URL,
        אײַנשליסן_אייגנשאַפֿטן: [URLResourceKey]?,
        אָפּציעס: FileManager.DirectoryEnumerationOptions = []
    ) throws -> [URL] {
        try contentsOfDirectory(
            at: וועג,
            includingPropertiesForKeys: אײַנשליסן_אייגנשאַפֿטן,
            options: אָפּציעס
        )
    }
}

// MARK: - FileManager.DirectoryEnumerationOptions
extension FileManager.DirectoryEnumerationOptions {
    @_transparent public static var איבערהיפּן_באַהאַלטענע: FileManager.DirectoryEnumerationOptions { .skipsHiddenFiles }
}

// MARK: - URLResourceKey
extension URLResourceKey {
    @_transparent public static var איז_סדר_שליסל: URLResourceKey { .isDirectoryKey }
}

// MARK: - URLResourceValues
extension URLResourceValues {
    @_transparent public var איז_סדר: Bool? { isDirectory }
}

// MARK: - URL additional wrappers
extension URL {
    @_alwaysEmitIntoClient
    public func אייגנשאַפֿט_ווערטן(פֿאַר שליסלען: Set<URLResourceKey>) throws -> URLResourceValues {
        try resourceValues(forKeys: שליסלען)
    }
}

// MARK: - NSWindowController init wrapper
extension NSWindowController {
    @_alwaysEmitIntoClient
    public convenience init(פֿענצטער: NSWindow) {
        self.init(window: פֿענצטער)
    }
}

// MARK: - NSView frame init wrapper
extension NSView {
    @_alwaysEmitIntoClient
    public convenience init(מסגרת: NSRect) {
        self.init(frame: מסגרת)
    }
}


// MARK: - NSMutableAttributedString Yiddish init
extension NSMutableAttributedString {
    @_alwaysEmitIntoClient
    public convenience init(
        טעקסט: String,
        אייגנשאַפֿטן: [NSAttributedString.Key: Any] = [:]
    ) {
        self.init(string: טעקסט, attributes: אייגנשאַפֿטן)
    }
}

// MARK: - NSTableColumn init wrapper
extension NSTableColumn {
    @_alwaysEmitIntoClient
    public convenience init(קענציכן: NSUserInterfaceItemIdentifier) {
        self.init(identifier: קענציכן)
    }
}

// MARK: - NSDocumentController
public typealias דאָקומענט_קאָנטראָלער = NSDocumentController

// MARK: - String.Encoding Yiddish names
extension String.Encoding {
    @_transparent public static var אוטפֿ8: String.Encoding { .utf8 }
}

// MARK: - Protocol method mappings
// These comment-based mappings are parsed by the Lexicon deriver to provide
// Yiddish↔English translations for protocol method names and parameter labels
// that cannot be expressed as typealiases or wrapper functions.

// NSViewController lifecycle
// mapping: באַלאַדן_בליק = loadView
// mapping: בליק_באַלאָדן = viewDidLoad

// NSDocument protocol
// mapping: מאַכן_פֿענצטער_קאָנטראָלערן = makeWindowControllers
// mapping: אויטאָ_שפּאָרט_אין_אָרט = autosavesInPlace
// mapping: לייענען = read
// mapping: דאַטן = data
// mapping: פֿון_טיפּ = ofType
// mapping: מקור = from

// NSApplicationDelegate protocol
// mapping: אַפּליקאַציע_פֿאַרטיק_אָנהייבן = applicationDidFinishLaunching
// mapping: אַפּליקאַציע_זאָל_עפֿענען_אומבאַטיטלטע_טעקע = applicationShouldOpenUntitledFile
// mapping: אַפּליקאַציע_שטיצט_זיכערן_ווידערהערשטעלונג = applicationSupportsSecureRestorableState

// NSOutlineViewDataSource / NSOutlineViewDelegate
// mapping: גליד_בליק_ג = outlineView
// mapping: צאָל_קינדער_פֿון_אינטעם = numberOfChildrenOfItem
// mapping: קינד = child
// mapping: פֿון_אינטעם = ofItem
// mapping: איז_אינטעם_אויפֿמאַכבאַר = isItemExpandable
// mapping: בליק_פֿאַר = viewFor
// mapping: טאַבעלע_קאָלאָנקע_פּ = tableColumn
// mapping: אינטעם = item
// mapping: אינדעקס = index
// mapping: מעלדונג_מ = notification
// mapping: שיקער = sender

