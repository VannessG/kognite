//
//  DashboardViewModel.swift
//  kognite
//
//  Created by Lemuel on 01/06/26.
//

import Foundation
import Combine
import FirebaseAuth

// Mengelola seluruh state dan logika bisnis halaman utama, mulai dari kalkulasi progres harian hingga operasi CRUD tugas dan pembaruan streak
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var tasks: [kognite.Task] = []
    private var scheduleId: String

    // Mengikat identitas pengguna aktif sebagai kunci relasi data agar seluruh operasi tugas terhubung ke akun yang benar sejak awal
    init() {
        self.scheduleId = FirebaseManager.shared.getCurrentUserId() ?? "default_user"
    }
    
    // Memberikan representasi nama terbaik dengan mengutamakan nama kustom atau memotong teks email agar sapaan pada dasbor terasa personal
    var currentUserDisplayName: String {
        let email = FirebaseManager.shared.getCurrentUserEmail() ?? "User"
        let name = FirebaseManager.shared.getCurrentDisplayName() ?? ""
        if name.isEmpty { return email.components(separatedBy: "@").first ?? "User" }
        return name
    }
    
    // Mengautentikasi ulang identitas pengguna melalui Firebase sebelum mengizinkan eksekusi tindakan berisiko tinggi seperti hapus atau edit tugas
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

    // Menarik seluruh data tugas milik pengguna dari Firestore agar tampilan dasbor selalu mencerminkan kondisi terkini
    func loadDashboardData() {
        Swift.Task {
            do {
                self.tasks = try await FirebaseManager.shared.fetchTasks(scheduleId: scheduleId)
            } catch {
                print("Gagal mengambil data: \(error)")
            }
        }
    }

    // Menghitung rasio tugas selesai terhadap total tugas untuk merender persentase progress bar pada tampilan dasbor
    func calculateProgress() -> Float {
        guard !tasks.isEmpty else { return 0.0 }
        return Float(tasks.filter { $0.isCompleted }.count) / Float(tasks.count)
    }

    // Menambahkan entri tugas baru ke daftar lokal secara optimistis sebelum dikonfirmasi ke database untuk menjaga responsivitas UI
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

    // Memperbarui konten tugas yang sudah ada secara lokal dan menyinkronkannya ke Firestore, lalu memuat ulang data jika terjadi kegagalan
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
    
    // Menandai tugas sebagai selesai lalu memicu pembaruan hitungan total tugas dan kalkulasi ulang streak konsistensi harian pengguna
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
    
    // Mengevaluasi tanggal aktivitas terakhir pengguna untuk menentukan apakah streak harus dilanjutkan, direset, atau dibiarkan agar tidak terhitung ganda dalam satu hari
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

    // Menghapus tugas dari daftar lokal dan database, serta mengoreksi hitungan total tugas selesai jika tugas yang dihapus sebelumnya sudah ditandai selesai
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
