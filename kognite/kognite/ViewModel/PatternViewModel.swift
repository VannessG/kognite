//
//  PatternViewModel.swift
//  kognite-se
//
//  Created by Davyne on 01/06/26.
//

import Foundation
import Combine

// Mengelola logika minigame pencocokan pola untuk memberikan sesi istirahat yang terstruktur dan mencegah transisi kognitif yang memicu konflik.
class PatternViewModel: ObservableObject {
    @Published var colorsCount: Int = 4
    @Published var message: String? = "Press Start to Play!"
    @Published var score: Int = 0
    @Published var activeTileIndex: Int? = nil
    @Published var isPlayerTurn: Bool = false
    
    private var sequence: [Int] = []
    private var playerStep: Int = 0
    
    // Menginisialisasi permainan baru dan menghapus riwayat pola sebelumnya agar anak bisa memulai tantangan dari awal.
    func startGame() {
        score = 0
        sequence.removeAll()
        nextRound()
    }
    
    // Menambahkan tingkat kesulitan dengan menambah satu urutan pola acak baru pada setiap putaran untuk melatih memori kerja pengguna.
    func nextRound() {
        isPlayerTurn = false
        playerStep = 0
        sequence.append(Int.random(in: 0..<colorsCount))
        message = "Watch the pattern..."
        playSequence()
    }
    
    // Memvisualisasikan urutan pola warna secara perlahan agar anak dengan ADHD dapat fokus memperhatikan dan mengingat urutan tersebut.
    func playSequence() {
        Swift.Task {
            try? await Swift.Task.sleep(nanoseconds: 1_000_000_000)
            
            for index in sequence {
                await MainActor.run { self.activeTileIndex = index }
                try? await Swift.Task.sleep(nanoseconds: 400_000_000)
                
                await MainActor.run { self.activeTileIndex = nil }
                try? await Swift.Task.sleep(nanoseconds: 200_000_000)
            }
            
            await MainActor.run {
                self.isPlayerTurn = true
                self.message = "Your turn!"
            }
        }
    }
    
    // Mengeksekusi strategi pengecekan input ketukan pengguna (benar atau salah) tanpa memengaruhi jalannya mesin timer utama aplikasi[cite: 1].
    func onTileTapped(index: Int) {
        guard isPlayerTurn else { return }
        
        activeTileIndex = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.activeTileIndex = nil
        }
        
        if sequence[playerStep] == index {
            playerStep += 1
            
            if playerStep == sequence.count {
                score += 1
                message = "Great Job! Next..."
                isPlayerTurn = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.nextRound()
                }
            }
        } else {
            message = "Game Over! You scored \(score)."
            isPlayerTurn = false
        }
    }
    
    // Memutar ulang pola yang sama apabila anak merasa kehilangan fokus dan membutuhkan bantuan visual sekali lagi untuk mengingat pola.
    func replaySequence() {
        guard isPlayerTurn && !sequence.isEmpty else { return }
        isPlayerTurn = false
        message = "Watch again..."
        playSequence()
    }
}