//
//  DetailPanel.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI


struct DetailPanel<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(padding)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 48, bottomLeadingRadius: 48)
                    .fill(Color(.cardGray))
                    .ignoresSafeArea()
            }
            
    }
}


#Preview {
    DetailPanel {
        Text("Detail")
    }
    .padding()
}
