//
//  ChickenIllustration.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI
import UIKit
import Lottie

struct ChickenIllustration: View {
    var pose: ChickenPose
    var height: CGFloat = 280
    
    private func loadinganimation() async -> LottieAnimationSource? {
        let name = pose.rawValue
        
        do {
            return try await DotLottieFile.named(name).animationSource
        } catch {
            print("Lottie gagal load \(name):", error)
            return LottieAnimation.named(name)?.animationSource
        }
    }

    var body: some View {
        Group {
            LottieView {
                await loadinganimation()
            } placeholder: {
                placeholder
            }
            .playing(loopMode: .loop)
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
