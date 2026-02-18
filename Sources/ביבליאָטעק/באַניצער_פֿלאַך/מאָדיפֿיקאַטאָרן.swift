import SwiftUI

extension View {
    // Layout
    @_transparent public func פּאַדינג(_ זײַטן: Edge.Set = .all, _ לענג: CGFloat? = nil) -> some View {
        self.padding(זײַטן, לענג)
    }

    @_transparent public func פּאַדינג(_ לענג: CGFloat) -> some View {
        self.padding(לענג)
    }

    @_transparent public func ראַמען(ברייט: CGFloat? = nil, הייך: CGFloat? = nil, אויסריכטונג: Alignment = .center) -> some View {
        self.frame(width: ברייט, height: הייך, alignment: אויסריכטונג)
    }

    @_transparent public func ראַמען(מינ_ברייט: CGFloat? = nil, אידעאַל_ברייט: CGFloat? = nil, מאַקס_ברייט: CGFloat? = nil, מינ_הייך: CGFloat? = nil, אידעאַל_הייך: CGFloat? = nil, מאַקס_הייך: CGFloat? = nil, אויסריכטונג: Alignment = .center) -> some View {
        self.frame(minWidth: מינ_ברייט, idealWidth: אידעאַל_ברייט, maxWidth: מאַקס_ברייט, minHeight: מינ_הייך, idealHeight: אידעאַל_הייך, maxHeight: מאַקס_הייך, alignment: אויסריכטונג)
    }

    // Background / Foreground
    @_transparent public func אונטערלייג(_ סטיל: some ShapeStyle) -> some View {
        self.background(סטיל)
    }

    @_transparent public func אונטערלייג<V: View>(_ אינהאַלט: V) -> some View {
        self.background(אינהאַלט)
    }

    @_transparent public func פֿאָרגרונט_פֿאַרב(_ פֿאַרב: Color) -> some View {
        self.foregroundStyle(פֿאַרב)
    }

    @_transparent public func פֿאָרגרונט_סטיל(_ סטיל: some ShapeStyle) -> some View {
        self.foregroundStyle(סטיל)
    }

    // Typography
    @_transparent public func שריפֿט(_ שריפֿט: Font?) -> some View {
        self.font(שריפֿט)
    }

    // Shape styling
    @_transparent public func עק_ראַדיוס(_ ראַדיוס: CGFloat) -> some View {
        self.cornerRadius(ראַדיוס)
    }

    @_transparent public func איבערלייג<V: View>(_ אינהאַלט: V, אויסריכטונג: Alignment = .center) -> some View {
        self.overlay(אינהאַלט, alignment: אויסריכטונג)
    }

    @_transparent public func דורכזיכטיקייט(_ ווערט: Double) -> some View {
        self.opacity(ווערט)
    }

    @_transparent public func שאָטן(פֿאַרב: Color = Color(.sRGBLinear, white: 0, opacity: 0.33), ראַדיוס: CGFloat, אויסריכטונג_אַרויף: CGFloat = 0, אויסריכטונג_זײַט: CGFloat = 0) -> some View {
        self.shadow(color: פֿאַרב, radius: ראַדיוס, x: אויסריכטונג_זײַט, y: אויסריכטונג_אַרויף)
    }

    @_transparent public func אַריבערשיבן(אַרויף: CGFloat = 0, זײַט: CGFloat = 0) -> some View {
        self.offset(x: זײַט, y: אַרויף)
    }

    // Lifecycle
    @_transparent public func בײַם_דערשײַנען(_ טוען: @escaping () -> Void) -> some View {
        self.onAppear(perform: טוען)
    }

    @_transparent public func בײַם_אַוועקגיין(_ טוען: @escaping () -> Void) -> some View {
        self.onDisappear(perform: טוען)
    }

    // Gestures
    @_transparent public func בײַם_טאַפּן(צאָל_טאַפּס: Int = 1, _ טוען: @escaping () -> Void) -> some View {
        self.onTapGesture(count: צאָל_טאַפּס, perform: טוען)
    }

    // Navigation
    @_transparent public func בלעטער_טיטל(_ טיטל: String) -> some View {
        self.navigationTitle(טיטל)
    }

    // Presentation
    @_transparent public func בלאַט<אינהאַלט: View>(איז_דאָ: Binding<Bool>, @ViewBuilder _ אינהאַלט_בויער: @escaping () -> אינהאַלט) -> some View {
        self.sheet(isPresented: איז_דאָ, content: אינהאַלט_בויער)
    }

    // Toolbar
    @_transparent public func וואָרצל_שטאַנגע<אינהאַלט: ToolbarContent>(@ToolbarContentBuilder _ אינהאַלט_בויער: () -> אינהאַלט) -> some View {
        self.toolbar(content: אינהאַלט_בויער)
    }
}
