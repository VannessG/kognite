//
//  AuthViewModel.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import Foundation
import Combine
import FirebaseAuth

// Menangani validasi form serta status kepemilikan sesi akun user untuk membatasi atau mengizinkan akses masuk aplikasi
@MainActor
class AuthViewModel: ObservableObject {
    @Published var emailInput: String = ""
    @Published var passwordInput: String = ""
    @Published var usernameInput: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // Menyediakan email user aktif saat ini untuk ditampilkan pada komponen view.
    var currentUserEmail: String {
        FirebaseManager.shared.getCurrentUserEmail() ?? "Email tidak ditemukan"
    }
    
    // Memberikan representasi nama panggilan terbaik, dan mengutamakan nama kustom atau memotong teks email, agar sapaan pada dasbor terasa personal
    var currentUsername: String {
        if let name = FirebaseManager.shared.getCurrentDisplayName(), !name.isEmpty {
            return name
        }
        return currentUserEmail.components(separatedBy: "@").first ?? "User"
    }
    
    // Mengirimkan permintaan verifikasi kredensial akun pengguna ke Firebase agar pengguna terdaftar dapat beralih masuk ke dalam fitur utama aplikasi
    func onLoginClick() {
        guard !emailInput.isEmpty, !passwordInput.isEmpty else {
            self.errorMessage = "Email dan Password tidak boleh kosong."
            self.showError = true
            return
        }
        
        Swift.Task {
            do {
                try await FirebaseManager.shared.login(email: emailInput, pass: passwordInput)
                self.isAuthenticated = true
            } catch {
                self.errorMessage = "Login gagal. Silakan periksa kembali email dan password Anda."
                self.showError = true
            }
        }
    }
    
    // Mendaftarkan entitas kredensial baru ke database server agar pengguna mendapatkan hak kepemilikan data profil pribadi
    func onRegisterClick() {
        guard !emailInput.isEmpty, !passwordInput.isEmpty, !usernameInput.isEmpty else {
            self.errorMessage = "Semua kolom harus diisi."
            self.showError = true
            return
        }
        
        Swift.Task {
            do {
                try await FirebaseManager.shared.register(username: usernameInput, email: emailInput, pass: passwordInput)
                self.isAuthenticated = true
            } catch {
                self.errorMessage = "Registrasi gagal. Email mungkin sudah digunakan atau format salah."
                self.showError = true
            }
        }
    }
    
    // Memutuskan token sesi aktif user dan mengosongkan sisa teks formulir lokal untuk mencegah kebocoran privasi akun saat keluar
    func logout() {
        do {
            try FirebaseManager.shared.logout()
            self.isAuthenticated = false
            self.emailInput = ""
            self.passwordInput = ""
            self.usernameInput = ""
        } catch {
            print("Gagal logout: \(error.localizedDescription)")
        }
    }
    
    // Memeriksa keberadaan unique ID user lokal yang masih aktif di background agar user dapat langsung masuk otomatis tanpa perlu melewati form login lagi
    func checkExistingSession() {
        if FirebaseManager.shared.getCurrentUserId() != nil {
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = false
        }
    }
}
