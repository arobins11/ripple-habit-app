//
//  RippleLottieView.swift
//  Ripple
//
//  Task 2 — Duty 2.3
//  A reusable SwiftUI view that plays a Lottie animation.
//
//  Why not call it "LottieView"? The Lottie package already has a type
//  named LottieView, so using that name would stop the project building.
//
//  Safe fallbacks:
//  • If the Lottie package has not been added yet, this still compiles
//    and shows an animated SF Symbol instead.
//  • If the .json animation file is missing, it shows the same fallback.
//  So this file can never break the build or crash the app.
//
//  Animation files: put the .json files anywhere inside the Ripple folder
//  (for example Ripple/Task2/Animations/). Names used by the app:
//      onboarding_welcome.json   habit_complete.json
//

import Foundation
import SwiftUI

#if canImport(Lottie)
import Lottie
#endif

struct RippleLottieView: View {

    /// The animation file name without ".json".
    let name: String
    /// Play forever (true) or once (false).
    var loops: Bool = false
    /// SF Symbol shown when the animation can't be loaded.
    var fallbackSymbol: String = "sparkles"
    /// Called when a play-once animation ends.
    var onFinished: (() -> Void)? = nil

    var body: some View {
        #if canImport(Lottie)
        if let animation = LottieAnimation.named(name) {
            LottieView(animation: animation)
                .playing(loopMode: loops ? .loop : .playOnce)
                .animationDidFinish { _ in
                    onFinished?()
                }
                .resizable()
                .scaledToFit()
        } else {
            FallbackSymbolAnimation(
                symbol: fallbackSymbol,
                loops: loops,
                onFinished: onFinished
            )
        }
        #else
        FallbackSymbolAnimation(
            symbol: fallbackSymbol,
            loops: loops,
            onFinished: onFinished
        )
        #endif
    }
}

/// A simple built-in animation used when Lottie isn't available.
private struct FallbackSymbolAnimation: View {

    let symbol: String
    let loops: Bool
    let onFinished: (() -> Void)?

    @State private var animate = false

    var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.accentColor)
            .scaleEffect(animate ? 1 : 0.6)
            .opacity(animate ? 1 : 0)
            .padding(8)
            .onAppear {
                if loops {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        animate = true
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                        animate = true
                    }
                    Task {
                        try? await Task.sleep(for: .milliseconds(700))
                        onFinished?()
                    }
                }
            }
    }
}

#Preview {
    RippleLottieView(name: "onboarding_welcome", loops: true, fallbackSymbol: "drop.circle.fill")
        .frame(width: 200, height: 200)
}
