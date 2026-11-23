//
//  BottomAction.swift
//  Agar
//

import SwiftUI


extension View {
    /// Pins a screen's primary action to the bottom edge.
    ///
    /// Every screen that ends in a button uses this, so the gap above the home indicator is
    /// the same everywhere. Four screens each rolling their own inset is how they drifted
    /// apart in the first place, so reach for this rather than a local one.
    ///
    /// A stack rather than `safeAreaInset`: an inset only shrinks the safe area, it does not
    /// shrink the frame, so a ScrollView above it keeps drawing its content underneath the
    /// button. That is what sent the recap list spilling out below its own white panel.
    func bottomAction<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            self
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            content()
                .padding()
        }
    }
}
