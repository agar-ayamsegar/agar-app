//
//  BottomAction.swift
//  Agar
//

import SwiftUI


extension View {
    func bottomAction<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        safeAreaInset(edge: .bottom) {
            content()
                .padding()
        }
    }
}
