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
    /// Treats `height` as a ceiling rather than a fixed size, so the art gives way when the
    /// panel is tight instead of pushing everything below it further down the screen.
    var flexible: Bool = false
    
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
        .frame(maxHeight: flexible ? height : nil)
        .frame(height: flexible ? nil : height)
        .accessibilityHidden(true)
    }

    
    private var placeholder: some View {
        Image(pose.rawValue)
            .resizable()
            .scaledToFit()
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
