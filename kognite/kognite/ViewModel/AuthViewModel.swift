//
//  AuthViewModel.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var emailInput: String = ""
    @Published var passwordInput: String = ""
    @Published var usernameInput: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    var currentUserEmail: String {
        FirebaseManager.shared.getCurrentUserEmail() ?? "Email tidak ditemukan"
    }
    
    var currentUsername: String {
        if let name = FirebaseManager.shared.getCurrentDisplayName(), !name.isEmpty {
            return name
        }
        return currentUserEmail.components(separatedBy: "@").first ?? "User"
    }
    
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
}
