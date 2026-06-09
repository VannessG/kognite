//
//  FirebaseManager.swift
//  kognite
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// Menjadi pusat kendali tunggal untuk mengelola seluruh autentikasi Firebase dan operasi berbasis data Firestore
class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {}

    // Memberikan akses masuk ke aplikasi bagi user yang telah terdaftar
    func login(email: String, pass: String) async throws {
        try await auth.signIn(withEmail: email, password: pass)
    }
    
    // Mendaftarkan akun baru sekaligus menginisialisasi dokumen profil awal pengguna di database
    func register(username: String, email: String, pass: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: pass)
        let newUser = User(id: result.user.uid, username: username, email: email, currentStreak: 0)
        try db.collection("users").document(result.user.uid).setData(from: newUser)
    }
    
    // Menutup sesi aktif demi menjaga keamanan akun pengguna saat keluar dari aplikasi
    func logout() throws {
        try auth.signOut()
    }
    
    // Menyediakan email pengguna aktif untuk keperluan verifikasi identitas atau view di sisi client
    func getCurrentUserEmail() -> String? {
        return auth.currentUser?.email
    }
    
    // Mengambil nama profil pengguna untuk keperluan view
    func getCurrentDisplayName() -> String? {
        return auth.currentUser?.displayName
    }
    
    // Menyediakan unique ID user aktif sebagai kunci relasi utama dokumen antar-koleksi di Firestore
    func getCurrentUserId() -> String? {
        return auth.currentUser?.uid
    }
    
    // Memastikan keamanan tambahan sebelum menjalankan tindakan sensitif dengan memvalidasi ulang identitas pengguna
    func reauthenticateUser(password: String) async throws {
        guard let user = auth.currentUser, let email = user.email else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sesi pengguna tidak valid."])
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }
    
    // Mengambil data metrik performa user untuk mengevaluasi pencapaian target harian mereka
    func fetchUserStats(userId: String) async throws -> (streak: Int, totalTasks: Int, lastActiveDate: String?) {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = snapshot.data() else { return (0, 0, nil) }
        
        let streak = data["currentStreak"] as? Int ?? 0
        let totalTasks = data["totalCompletedTasks"] as? Int ?? 0
        let lastActiveDate = data["lastActiveDate"] as? String
        
        return (streak, totalTasks, lastActiveDate)
    }
    
    // Memperbarui status retensi harian pengguna agar perhitungan streak tetap akurat
    func updateUserStreakAndDate(userId: String, newStreak: Int, dateStr: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "currentStreak": newStreak,
            "lastActiveDate": dateStr
        ])
    }
    
    // Memuat data profil lengkap user untuk di convert menjadi objek model User
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
     
    // Mengambil daftar penghargaan yang berhak diakses atau diklaim oleh pengguna berdasarkan riwayat performa mereka.
    func fetchRewards(userId: String) async throws -> [Reward] {
        let snapshot = try await db.collection("rewards").whereField("userId", isEqualTo: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Reward.self) }
    }
    
    // Menyimpan rekam jejak status klaim *reward* terbaru pengguna agar pencatatan di database tetap sinkron.
    func saveReward(_ reward: Reward, userId: String) throws {
        guard let id = reward.id else { return }
        try db.collection("rewards").document(id).setData(from: reward)
    }
}
