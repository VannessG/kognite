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
    
    func fetchUserStats(userId: String) async throws -> (streak: Int, totalTasks: Int, lastActiveDate: String?) {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = snapshot.data() else { return (0, 0, nil) }
        
        let streak = data["currentStreak"] as? Int ?? 0
        let totalTasks = data["totalCompletedTasks"] as? Int ?? 0
        
        let lastActiveDate = data["lastActiveDate"] as? String
        
        return (streak, totalTasks, lastActiveDate)
    }
    
    func updateUserStreakAndDate(userId: String, newStreak: Int, dateStr: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "currentStreak": newStreak,
            "lastActiveDate": dateStr
        ])
    }
    
    func fetchUser(userId: String) async throws -> User? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        return try snapshot.data(as: User.self)
    }
}
