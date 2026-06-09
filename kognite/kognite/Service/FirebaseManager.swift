//
//  FirebaseManager.swift
//  kognite
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {}
    
    // MARK: - Auth
    
    func login(email: String, pass: String) async throws {
        try await auth.signIn(withEmail: email, password: pass)
    }
    
    func register(username: String, email: String, pass: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: pass)
        let newUser = User(id: result.user.uid, username: username, email: email, currentStreak: 0)
        try db.collection("users").document(result.user.uid).setData(from: newUser)
    }
    
    func logout() throws {
        try auth.signOut()
    }
    
    func getCurrentUserEmail() -> String? {
        return auth.currentUser?.email
    }
    
    func getCurrentDisplayName() -> String? {
        return auth.currentUser?.displayName
    }
    
    func getCurrentUserId() -> String? {
        return auth.currentUser?.uid
    }
    
    func reauthenticateUser(password: String) async throws {
        guard let user = auth.currentUser, let email = user.email else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sesi pengguna tidak valid."])
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }
    
    // MARK: - Users & Stats
    
    func fetchUserStats(userId: String) async throws -> (streak: Int, totalTasks: Int, lastActiveDate: String?) {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = snapshot.data() else { return (0, 0, nil) }
        
        let streak = data["currentStreak"] as? Int ?? 0
        let totalTasks = data["totalCompletedTasks"] as? Int ?? 0
        
        // Mengambil data langsung dari Firebase tanpa memerlukan struct User
        let lastActiveDate = data["lastActiveDate"] as? String
        
        return (streak, totalTasks, lastActiveDate)
    }
    
    // TAMBAHAN: Fungsi baru untuk menyimpan streak dan tanggal hari ini
    func updateUserStreakAndDate(userId: String, newStreak: Int, dateStr: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "currentStreak": newStreak,
            "lastActiveDate": dateStr // Firebase otomatis membuat kolom ini di DB!
        ])
    }
    
    func fetchUser(userId: String) async throws -> User? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        return try snapshot.data(as: User.self)
    }
    
    // MARK: - Tasks Management
    
    func fetchTasks(scheduleId: String) async throws -> [kognite.Task] {
        let snapshot = try await db.collection("tasks").whereField("scheduleId", isEqualTo: scheduleId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: kognite.Task.self) }
    }
    
    func addTask(_ task: kognite.Task) throws {
        guard let id = task.id else { return }
        try db.collection("tasks").document(id).setData(from: task)
    }
    
    func updateTask(_ task: kognite.Task) throws {
        guard let id = task.id else { return }
        try db.collection("tasks").document(id).setData(from: task)
    }
    
    func deleteTask(id: String) async throws {
        try await db.collection("tasks").document(id).delete()
    }
    
    func incrementUserTaskCount(userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "totalCompletedTasks": FieldValue.increment(Int64(1))
        ])
    }
    
    func decrementUserTaskCount(userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "totalCompletedTasks": FieldValue.increment(Int64(-1))
        ])
    }
    
    // MARK: - Activities Management
    
    func fetchActivities(scheduleId: String) async throws -> [ScheduleActivity] {
        let snapshot = try await db.collection("activities").whereField("scheduleId", isEqualTo: scheduleId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ScheduleActivity.self) }
    }
    
    func addActivity(_ activity: ScheduleActivity) throws {
        guard let id = activity.id else { return }
        try db.collection("activities").document(id).setData(from: activity)
    }
    
    func updateActivity(_ activity: ScheduleActivity) throws {
        guard let id = activity.id else { return }
        try db.collection("activities").document(id).setData(from: activity)
    }
    
    func deleteActivity(id: String) async throws {
        try await db.collection("activities").document(id).delete()
    }
    
    // MARK: - Rewards Management
    
    func fetchRewards(userId: String) async throws -> [Reward] {
        let snapshot = try await db.collection("rewards").whereField("userId", isEqualTo: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Reward.self) }
    }
    
    func saveReward(_ reward: Reward, userId: String) throws {
        guard let id = reward.id else { return }
        try db.collection("rewards").document(id).setData(from: reward)
    }
}
