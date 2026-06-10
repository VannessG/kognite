//
//  LottieView.swift
//  kognite
//
//  Created by Vanness Aurelius Gunawan on 31/05/26.
//

import SwiftUI
import Lottie

// Menjembatani komponen animasi Lottie ke dalam ekosistem SwiftUI agar aplikasi dapat merender animasi kompleks secara responsif
struct LottieView: UIViewRepresentable {
    var animationName: String
    var loopMode: LottieLoopMode = .loop
    var isPlaying: Bool = true
    
    // Menginisialisasi komponen tampilan dasar di awal siklus agar aset animasi siap menerima instruksi pemutaran dari state SwiftUI
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        
        if let animation = LottieAnimation.named(animationName) {
            animationView.animation = animation
        }
        
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        
        if isPlaying { animationView.play() }
        
        return animationView
    }
    
    // Menyinkronkan status putar atau jeda dari logika ViewModel ke tampilan UI agar pergerakan visual selalu selaras dengan kondisi pengguna (misalnya saat timer di jeda)
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if isPlaying {
            if !uiView.isAnimationPlaying { uiView.play() }
        } else {
            uiView.pause()
        }
    }
}
