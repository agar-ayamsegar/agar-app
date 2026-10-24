//
//  AppButton.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI


enum AppButtonStyle {
    
    // TODO: add more
    case primary,
        secondary
    
    
    var background: Color {
        switch self {
        case .primary:
            return Color("Primary")
        case .secondary:
            return .white
        }
    }
    
    var foreground: Color {
        switch self {
        case .primary:
            return .white
        case .secondary:
            return Color("Secondary")
        }
    }
    
    var border: CGFloat {
        switch self {
        case .primary:
            return 0
        case .secondary:
            return 2
        }
    }
}



struct AppButton: View {
    var label: String
    var style: AppButtonStyle = .primary
    var onClick: () -> Void
    
    var body: some View {
        Button {
            
        } label: {
            VStack {
                Text(label)
                    .font(.default)
                    .foregroundStyle(style.foreground)
                    .bold()
            }
            .padding()
            .frame(minHeight: 56)
            .frame(maxWidth: .infinity)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: style.border))
                    .fill(style.foreground)
            }
            .shadow(radius: 10)
        }
    }
}


#Preview {
    HStack {
        AppButton(label: "Click me") {
            
        }
        
        AppButton(label: "Click me", style: .secondary) {
            
        }
    }

}
