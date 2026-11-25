//
//  PrimaryActionButton.swift
//  Agar
//

import SwiftUI

/// The one blue button the app uses for the primary action on every screen.
///
/// Native prominent liquid glass tinted with ActionBlueDeep: filled, so it reads as the one
/// action on the screen next to the clear-glass controls. Every screen goes through this, so
/// the four of them cannot drift apart again the way their spacing once did.
struct PrimaryActionButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .tint(.actionBlueDeep)
    }
}

extension PrimitiveButtonStyle where Self == PrimaryActionButtonStyle {
    static var primaryAction: PrimaryActionButtonStyle { .init() }
}


#Preview {
    VStack(spacing: 20) {
        Button("Mulai Pemeriksaan") {}
        Button("Simpan & Lihat Laporan") {}
    }
    .buttonStyle(.primaryAction)
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.surfaceCream)
}
