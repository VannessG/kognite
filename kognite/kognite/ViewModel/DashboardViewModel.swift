//
//  DashboardViewModel.swift
//  kognite
//
//  Created by Lemuel on 01/06/26.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var tasks: [kognite.Task] = []
    private var scheduleId: String

    init() {
        self.scheduleId = FirebaseManager.shared.getCurrentUserId() ?? "default_user"
    }
    
    var currentUserDisplayName: String {
        let email = FirebaseManager.shared.getCurrentUserEmail() ?? "User"
        let name = FirebaseManager.shared.getCurrentDisplayName() ?? ""
        if name.isEmpty { return email.components(separatedBy: "@").first ?? "User" }
        return name
    }
    
    func verifyPassword(password: String, completion: @escaping (Bool, String) -> Void) {
        Swift.Task {
            do {
                try await FirebaseManager.shared.reauthenticateUser(password: password)
                completion(true, "Berhasil")
            } catch let error as NSError {
                let msg = error.code == AuthErrorCode.wrongPassword.rawValue ? "Password salah." : error.localizedDescription
                completion(false, msg)
            }
        }
    }

    func loadDashboardData() {
        Swift.Task {
            do {
                self.tasks = try await FirebaseManager.shared.fetchTasks(scheduleId: scheduleId)
            } catch {
                print("Gagal mengambil data: \(error)")
            }
        }
    }

    func calculateProgress() -> Float {
        guard !tasks.isEmpty else { return 0.0 }
        return Float(tasks.filter { $0.isCompleted }.count) / Float(tasks.count)
    }

    func addTask(title: String, deadline: String, description: String, color: String) {
        let newId = UUID().uuidString
        let newTask = kognite.Task(
            id: newId, scheduleId: scheduleId, title: title.trimmingCharacters(in: .whitespaces),
            deadline: deadline, description: description.isEmpty ? nil : description, isCompleted: false, color: color
        )
        
        self.tasks.append(newTask)
        
        do {
            try FirebaseManager.shared.addTask(newTask)
        } catch {
            self.tasks.removeAll(where: { $0.id == newId })
        }
    }

    func updateTask(id: String, title: String, deadline: String, description: String) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        var updatedTask = tasks[index]
        updatedTask.title = title
        updatedTask.deadline = deadline
        updatedTask.description = description.isEmpty ? nil : description
        
        tasks[index] = updatedTask
        
        do {
            try FirebaseManager.shared.updateTask(updatedTask)
        } catch {
            self.loadDashboardData()
        }
    }
    
    func completeTask(task: kognite.Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updated = tasks[index]
        updated.isCompleted = true
        tasks[index] = updated

        Swift.Task {
            do {
                try FirebaseManager.shared.updateTask(updated)
                
                try await FirebaseManager.shared.incrementUserTaskCount(userId: scheduleId)
                
                try await processStreakUpdate()
                
            } catch {
                self.loadDashboardData()
                print("Gagal menyelesaikan task: \(error.localizedDescription)")
            }
        }
    }
    
    private func processStreakUpdate() async throws {
        let stats = try await FirebaseManager.shared.fetchUserStats(userId: scheduleId)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let todayStr = formatter.string(from: Date())
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayStr = formatter.string(from: yesterday)
        
        let lastActive = stats.lastActiveDate
        
        if lastActive == todayStr {
            return
        }
        
        var newStreak = 1
        
        if lastActive == yesterdayStr {
            newStreak = stats.streak + 1
        }
        
        try await FirebaseManager.shared.updateUserStreakAndDate(
            userId: scheduleId,
            newStreak: newStreak,
            dateStr: todayStr
        )
    }

    func deleteTask(id: String) {
        let isTaskCompleted = self.tasks.first(where: { $0.id == id })?.isCompleted ?? false
        
        self.tasks.removeAll(where: { $0.id == id })
        
        Swift.Task {
            do {
                try await FirebaseManager.shared.deleteTask(id: id)
                
                if isTaskCompleted {
                    try await FirebaseManager.shared.decrementUserTaskCount(userId: scheduleId)
                }
            } catch {
                self.loadDashboardData()
                print("Gagal menghapus task: \(error.localizedDescription)")
            }
        }
    }
}
