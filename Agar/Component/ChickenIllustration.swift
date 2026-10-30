//
//  ChickenIllustration.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI
import UIKit


struct ChickenIllustration: View {
    var pose: ChickenPose
    var height: CGFloat = 280

    var body: some View {
        Group {
            // fallback to placeholder until the asset is added
            if UIImage(named: pose.rawValue) != nil {
                Image(pose.rawValue)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "bird")
                        .font(.system(size: 48))

                    Text(pose.rawValue)
                        .font(.caption.monospaced())
                }
            }
            .foregroundStyle(.secondary)
    }
}


#Preview {
    HStack {
        ForEach(ChickenPose.allCases, id: \.self) { pose in
            ChickenIllustration(pose: pose, height: 120)
        }
    }
    .padding()
}
