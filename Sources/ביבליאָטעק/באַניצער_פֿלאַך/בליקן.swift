@_exported import SwiftUI

// MARK: - Core View Protocol
public typealias בליק = View


// MARK: - Basic Views
public typealias טעקסט = Text
public typealias קנעפּל = Button
public typealias בילד = Image
public typealias רשימה = List
public typealias נאַוויגאַציע_שטאַפּל = NavigationStack
public typealias שטאַפּל_ה = HStack
public typealias שטאַפּל_וו = VStack
public typealias שטאַפּל_צ = ZStack
public typealias בלעטל = ScrollView
public typealias פּלאַצהאַלטער = Spacer
public typealias טיילער = Divider

// MARK: - Iteration / Navigation / Structural
public typealias פֿאַר_יעדן = ForEach
public typealias ליידיקע_בליק = EmptyView
public typealias נאַוויגאַציע_לינק = NavigationLink
public typealias וואָרקזייג_אינטעם = ToolbarItem
public typealias וואָרקזייג_פּלאַצירונג = ToolbarItemPlacement
public typealias פֿענצטער_גרופּע = WindowGroup

// MARK: - App / Scene protocols
public typealias אַפּליקאַציע_פּראָטאָקאָל = App
public typealias סצענע = Scene

// MARK: - Form / Section / Controls
public typealias פֿאָרם = Form
public typealias אָפּטייל = Section
public typealias אויסקלאַפּן = Toggle
public typealias שיבער = Slider
public typealias אויסקלײַבער = Picker
public typealias דאַטום_אויסקלײַבער = DatePicker
public typealias לאָשן_אויסקלײַבן = TabView
public typealias טעקסט_פֿעלד = TextField
public typealias טעקסט_רעדאַקטאָר = TextEditor
public typealias עטיקעט = Label
public typealias פּראָגרעס_בליק = ProgressView
public typealias מעניו = Menu

// MARK: - Image Yiddish init (systemName: → סיסטעם_נאָמען:)
extension Image {
    @_transparent public init(סיסטעם_נאָמען: String) {
        self.init(systemName: סיסטעם_נאָמען)
    }
}

// MARK: - Toggle Yiddish init (isOn: → איז_אָן:)
extension Toggle {
    @_transparent public init(איז_אָן: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self.init(isOn: איז_אָן, label: label)
    }
}

// MARK: - TextField Yiddish init (text: → טעקסט:)
extension TextField where Label == Text {
    @_transparent public init(_ פּלאַצהאַלטער: LocalizedStringKey, טעקסט: Binding<String>) {
        self.init(פּלאַצהאַלטער, text: טעקסט)
    }

    @_transparent public init(_ פּלאַצהאַלטער: String, טעקסט: Binding<String>) {
        self.init(פּלאַצהאַלטער, text: טעקסט)
    }
}

// MARK: - TextEditor Yiddish init (text: → טעקסט:)
extension TextEditor {
    @_transparent public init(טעקסט: Binding<String>) {
        self.init(text: טעקסט)
    }
}

// MARK: - Button Yiddish init with role: → ראָלע:
extension Button where Label == Text {
    @_transparent public init(_ טיטל: LocalizedStringKey, ראָלע: ButtonRole?, אַקציע: @escaping () -> Void) {
        self.init(טיטל, role: ראָלע, action: אַקציע)
    }

    @_transparent public init(_ טיטל: String, ראָלע: ButtonRole?, אַקציע: @escaping () -> Void) {
        self.init(טיטל, role: ראָלע, action: אַקציע)
    }
}

// MARK: - ToolbarItem Yiddish init (placement: → פּלאַצירונג:)
extension ToolbarItem where ID == () {
    @_transparent public init(פּלאַצירונג: ToolbarItemPlacement = .automatic, @ViewBuilder אינהאַלט: () -> Content) {
        self.init(placement: פּלאַצירונג, content: אינהאַלט)
    }
}

// MARK: - Label Yiddish init (systemImage: via עטיקעט)
extension Label where Title == Text, Icon == Image {
    @_transparent public init(_ טיטל: LocalizedStringKey, סיסטעם_בילד: String) {
        self.init(טיטל, systemImage: סיסטעם_בילד)
    }

    @_transparent public init(_ טיטל: String, סיסטעם_בילד: String) {
        self.init(טיטל, systemImage: סיסטעם_בילד)
    }
}

// MARK: - VStack Yiddish init (alignment:/spacing:/content: → אויסריכטונג:/אָפּשטאַנד:/אינהאַלט:)
extension VStack {
    @_transparent public init(אויסריכטונג: HorizontalAlignment = .center, אָפּשטאַנד: CGFloat? = nil, @ViewBuilder אינהאַלט: () -> Content) {
        self.init(alignment: אויסריכטונג, spacing: אָפּשטאַנד, content: אינהאַלט)
    }
}

// MARK: - HStack Yiddish init (alignment:/spacing:/content: → אויסריכטונג:/אָפּשטאַנד:/אינהאַלט:)
extension HStack {
    @_transparent public init(אויסריכטונג: VerticalAlignment = .center, אָפּשטאַנד: CGFloat? = nil, @ViewBuilder אינהאַלט: () -> Content) {
        self.init(alignment: אויסריכטונג, spacing: אָפּשטאַנד, content: אינהאַלט)
    }
}

// MARK: - NavigationLink Yiddish init (destination:/label: → ציל:/לאַבל:)
extension NavigationLink {
    @_transparent public init(ציל: @autoclosure @escaping () -> Destination, @ViewBuilder לאַבל: () -> Label) {
        self.init(destination: ציל, label: לאַבל)
    }
}

// MARK: - ToolbarItemPlacement Yiddish values
extension ToolbarItemPlacement {
    @_transparent public static var הויפּט_אַקציע: ToolbarItemPlacement { .primaryAction }
    @_transparent public static var ביטול_אַקציע: ToolbarItemPlacement { .cancellationAction }
    @_transparent public static var באַשטעטיקונג_אַקציע: ToolbarItemPlacement { .confirmationAction }
    @_transparent public static var אויטאָמאַטיש: ToolbarItemPlacement { .automatic }
    #if os(iOS) || os(visionOS)
    @_transparent public static var נאַוויגאַציע_שטאַנגע_טרעילינג: ToolbarItemPlacement { .navigationBarTrailing }
    #endif
}

// MARK: - Font Yiddish values
extension Font {
    @_transparent public static var קעפּל: Font { .headline }
    @_transparent public static var אונטערשריפֿט: Font { .caption }
    @_transparent public static var גרויסער_טיטל: Font { .largeTitle }
    @_transparent public static var גוף: Font { .body }
    @_transparent public static var טיטל_שריפֿט: Font { .title }
    @_transparent public static var טיטל2: Font { .title2 }
    @_transparent public static var טיטל3: Font { .title3 }
    @_transparent public static var פֿוסנאָטע: Font { .footnote }
    @_transparent public static var אונטערקעפּל: Font { .subheadline }
}

// MARK: - HorizontalAlignment Yiddish values
extension HorizontalAlignment {
    @_transparent public static var אָנהייב: HorizontalAlignment { .leading }
    @_transparent public static var סוף: HorizontalAlignment { .trailing }
    @_transparent public static var מיטן: HorizontalAlignment { .center }
}

// MARK: - VerticalAlignment Yiddish values
extension VerticalAlignment {
    @_transparent public static var אויבן: VerticalAlignment { .top }
    @_transparent public static var אונטן: VerticalAlignment { .bottom }
    @_transparent public static var מיטן: VerticalAlignment { .center }
}

// MARK: - Edge.Set Yiddish values
extension Edge.Set {
    @_transparent public static var אונטן: Edge.Set { .bottom }
    @_transparent public static var אויבן: Edge.Set { .top }
}

// MARK: - Protocol method mappings
// SwiftUI View protocol
// mapping: גוף = body
// Identifiable protocol
// mapping: קענונג = id
// SwiftUI parameter labels
// mapping: עטיקעט_צ = label
