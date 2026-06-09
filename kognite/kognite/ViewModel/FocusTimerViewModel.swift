//
//  FocusTimerViewModel.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import Foundation
import SwiftUI
import Combine

enum TimerMode: String {
    case focus = "Focus Time"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
}

enum AnimationChoice: String, CaseIterable {
    case sloth = "Zen Sloth"
    case bear = "Disco Bear"
    case avocado = "Walk-ocado"
    case panda = "Happy Panda"
    case cat = "Sleepy Cat"
    
    var icon: String {
        switch self {
        case .sloth:   return "leaf.fill"
        case .bear:    return "pawprint.fill"
        case .avocado: return "fork.knife"
        case .panda:   return "face.smiling.inverse"
        case .cat:     return "hare.fill"
        }
    }
    
    var lottieFileName: String? {
        switch self {
        case .sloth: return "sloth"
        case .bear: return "bear"
        case .avocado: return "avocado"
        case .panda: return "panda"
        case .cat: return "cat"
        }
    }
}

@MainActor
class FocusTimerViewModel: ObservableObject {
    @Published var focusMinutes: Int
    @Published var shortBreakMinutes: Int
    @Published var longBreakMinutes: Int
    
    @Published var currentMode: TimerMode = .focus
    @Published var timeRemaining: Int = 0
    @Published var isPlaying: Bool = false
    @Published var selectedAnimation: AnimationChoice = .sloth
    
    @Published var pomodoroCount: Int = 0
    private var activeTimer: Timer?

    init() {
        let userId = FirebaseManager.shared.getCurrentUserId() ?? "default_user"
        let defaults = UserDefaults.standard
        
        self.focusMinutes = defaults.integer(forKey: "\(userId)_focusMinutes") == 0 ? 25 : defaults.integer(forKey: "\(userId)_focusMinutes")
        self.shortBreakMinutes = defaults.integer(forKey: "\(userId)_shortBreakMinutes") == 0 ? 5 : defaults.integer(forKey: "\(userId)_shortBreakMinutes")
        self.longBreakMinutes = defaults.integer(forKey: "\(userId)_longBreakMinutes") == 0 ? 15 : defaults.integer(forKey: "\(userId)_longBreakMinutes")
        
        self.timeRemaining = self.focusMinutes * 60
    }
    
    func toggleTimer() {
        isPlaying.toggle()
        if isPlaying {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    private func startTimer() {
        activeTimer?.invalidate()
        activeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
    }
    
    private func stopTimer() {
        activeTimer?.invalidate()
        activeTimer = nil
    }

    func tick() {
        if isPlaying && timeRemaining > 0 {
            timeRemaining -= 1
            
            if timeRemaining == 0 {
                nextMode()
                isPlaying = true
                startTimer()
            }
        }
    }
    
    func resetTimer() {
        isPlaying = false
        stopTimer()
        timeRemaining = getTotalTimeForCurrentMode()
    }
    
    func nextMode() {
        switch currentMode {
        case .focus:
            pomodoroCount += 1
            if pomodoroCount % 4 == 0 {
                currentMode = .longBreak
            } else {
                currentMode = .shortBreak
            }
        case .shortBreak, .longBreak:
            currentMode = .focus
        }
        resetTimer()
    }
    
    func applySettings(focus: Int, short: Int, long: Int) {
        self.focusMinutes = focus
        self.shortBreakMinutes = short
        self.longBreakMinutes = long
        
        let userId = FirebaseManager.shared.getCurrentUserId() ?? "default_user"
        let defaults = UserDefaults.standard
        defaults.set(focus, forKey: "\(userId)_focusMinutes")
        defaults.set(short, forKey: "\(userId)_shortBreakMinutes")
        defaults.set(long, forKey: "\(userId)_longBreakMinutes")
        
        resetTimer()
    }
    
    private func getTotalTimeForCurrentMode() -> Int {
        switch currentMode {
        case .focus: return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }
    
    // Panggil async throws melalui Task, lalu lempar balik completion boolean untuk View
    func verifyPassword(password: String, completion: @escaping (Bool) -> Void) {
        Swift.Task {
            do {
                try await FirebaseManager.shared.reauthenticateUser(password: password)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
    
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: CGFloat {
        let totalTime = getTotalTimeForCurrentMode()
        return totalTime > 0 ? CGFloat(timeRemaining) / CGFloat(totalTime) : 0
    }
}
