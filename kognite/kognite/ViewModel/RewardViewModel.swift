//
//  RewardViewModel.swift
//  kognite-se
//
//  Created by Davyne on 01/06/26.
//

import Foundation
import Combine

@MainActor
class RewardViewModel: ObservableObject {
    @Published var rewards: [Reward] = []
    @Published var currentStreak: Int = 0
    @Published var totalCompletedTasks: Int = 0
    
    func loadRewards() {
        let userId = FirebaseManager.shared.getCurrentUserId() ?? "default_user"
        
        Swift.Task {
            do {
                let stats = try await FirebaseManager.shared.fetchUserStats(userId: userId)
                self.currentStreak = stats.streak
                self.totalCompletedTasks = stats.totalTasks
                
                let fetchedRewards = try await FirebaseManager.shared.fetchRewards(userId: userId)
                
                if fetchedRewards.isEmpty {
                    let defaults = self.defaultRewards(userId: userId)
                    self.rewards = defaults
                    for r in defaults {
                        // PERBAIKAN: Hapus 'await'
                        try? FirebaseManager.shared.saveReward(r, userId: userId)
                    }
                } else {
                    self.rewards = fetchedRewards.sorted { Int($0.id ?? "0") ?? 0 < Int($1.id ?? "0") ?? 0 }
                }
                
                self.checkAndUnlockRewards(userId: userId)
                
            } catch {
                print("Gagal mengambil data rewards: \(error.localizedDescription)")
            }
        }
    }
    
    func checkAndUnlockRewards(userId: String) {
        var needsUpdate = false
        
        for i in 0..<rewards.count {
            let milestone = rewards[i].milestone
            let requiredStreak = rewards[i].streakRequired
            
            let isMilestoneMet = milestone == 0 || totalCompletedTasks >= milestone
            let isStreakMet = requiredStreak == 0 || currentStreak >= requiredStreak
            
            if isMilestoneMet && isStreakMet && !rewards[i].isUnlocked {
                rewards[i].isUnlocked = true
                
                let formatter = DateFormatter()
                formatter.dateFormat = "dd MMM yyyy"
                rewards[i].dateAchieved = formatter.string(from: Date())
                
                let unlockedReward = rewards[i]
                Swift.Task {
                    // PERBAIKAN: Hapus 'await'
                    try? FirebaseManager.shared.saveReward(unlockedReward, userId: userId)
                }
                
                needsUpdate = true
            }
        }
        
        if needsUpdate {
            self.objectWillChange.send()
        }
    }
    
    private func defaultRewards(userId: String) -> [Reward] {
        return [
            Reward(id: "1", userId: userId, title: "First Step", iconName: "figure.walk", milestone: 1, description: "Completed your very first task.", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "2", userId: userId, title: "Getting Started", iconName: "star.fill", milestone: 3, description: "Completed 3 tasks in total.", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "3", userId: userId, title: "3-Day Streak", iconName: "flame.fill", milestone: 0, description: "Complete schedules for 3 consecutive days.", streakRequired: 3, dateAchieved: "", isUnlocked: false),
            Reward(id: "4", userId: userId, title: "Task Rookie", iconName: "checkmark.circle.fill", milestone: 5, description: "Completed 5 tasks.", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "5", userId: userId, title: "7-Day Streak", iconName: "flame.fill", milestone: 0, description: "One focused week!", streakRequired: 7, dateAchieved: "", isUnlocked: false),
            Reward(id: "6", userId: userId, title: "Task Explorer", iconName: "checkmark.circle.fill", milestone: 10, description: "Completed 10 tasks.", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "7", userId: userId, title: "Task Enthusiast", iconName: "list.bullet.rectangle.fill", milestone: 15, description: "Completed 15 tasks.", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "8", userId: userId, title: "Task Master", iconName: "briefcase.fill", milestone: 25, description: "Completed 25 tasks. Great progress!", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "9", userId: userId, title: "Task Champion", iconName: "medal.fill", milestone: 50, description: "Half a hundred! Completed 50 tasks.", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "10", userId: userId, title: "Task Legend", iconName: "trophy.fill", milestone: 100, description: "Completed 100 tasks. You are a legend!", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "11", userId: userId, title: "Productivity Machine", iconName: "gearshape.2.fill", milestone: 250, description: "Completed 250 tasks. Unstoppable engine!", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "12", userId: userId, title: "Kognite Grandmaster", iconName: "crown.fill", milestone: 500, description: "Completed 500 tasks. Supreme productivity!", streakRequired: 0, dateAchieved: "", isUnlocked: false),
            Reward(id: "13", userId: userId, title: "Weekend Warrior", iconName: "bolt.fill", milestone: 0, description: "Maintained a 2-day streak.", streakRequired: 2, dateAchieved: "", isUnlocked: false),
            Reward(id: "14", userId: userId, title: "High Five", iconName: "hand.raised.fill", milestone: 0, description: "Achieved a 5-day productivity streak.", streakRequired: 5, dateAchieved: "", isUnlocked: false),
            Reward(id: "15", userId: userId, title: "Fortnight Focus", iconName: "calendar.badge.clock", milestone: 0, description: "Two full weeks of consistency (14 Days).", streakRequired: 14, dateAchieved: "", isUnlocked: false),
            Reward(id: "16", userId: userId, title: "Habit Builder", iconName: "hammer.fill", milestone: 0, description: "It takes 21 days to build a habit.", streakRequired: 21, dateAchieved: "", isUnlocked: false),
            Reward(id: "17", userId: userId, title: "Monthly Master", iconName: "calendar.circle.fill", milestone: 0, description: "A solid 30-day streak. Amazing!", streakRequired: 30, dateAchieved: "", isUnlocked: false),
            Reward(id: "18", userId: userId, title: "Consistency King", iconName: "timer", milestone: 0, description: "Achieved a 50-day streak.", streakRequired: 50, dateAchieved: "", isUnlocked: false),
            Reward(id: "19", userId: userId, title: "Unstoppable", iconName: "flame.circle.fill", milestone: 0, description: "2 months straight! (60-Day Streak)", streakRequired: 60, dateAchieved: "", isUnlocked: false),
            Reward(id: "20", userId: userId, title: "Century Streak", iconName: "100.circle.fill", milestone: 0, description: "100 days of uninterrupted focus. Phenomenal!", streakRequired: 100, dateAchieved: "", isUnlocked: false)
        ]
    }
}
