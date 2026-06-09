//
//  LottieView.swift
//  kognite
//
//  Created by Vanness Aurelius Gunawan on 31/05/26.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var animationName: String
    var loopMode: LottieLoopMode = .loop
    var isPlaying: Bool = true
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        
        if let animation = LottieAnimation.named(animationName) {
            animationView.animation = animation
        }
        
        // Ganti ke .scaleAspectFit agar seluruh objek animasi masuk ke dalam frame
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        
        if isPlaying { animationView.play() }
        
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if isPlaying {
            if !uiView.isAnimationPlaying { uiView.play() }
        } else {
            uiView.pause()
        }
    }
}
