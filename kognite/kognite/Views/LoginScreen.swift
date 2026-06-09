//
//  LoginScreen.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import SwiftUI

// Menampilkan halaman login saat pertama kali membuka aplikasi dan ingin masuk ke aplikasi (sudah memiliki akun)
struct LoginScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Welcome Back!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Sign in to continue your journey")
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        TextField("Email", text: $viewModel.emailInput)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                    
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        SecureField("Password", text: $viewModel.passwordInput)
                        Image(systemName: "eye.slash")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                }
                .padding(.horizontal, 20)
                
                Button(action: {
                    viewModel.onLoginClick()
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.35, green: 0.65, blue: 0.45)) // Primary Green
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                NavigationLink(destination: RegisterScreen(viewModel: viewModel)) {
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        Text("Register")
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                    }
                }
                
                Spacer()
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all))
            // Tampilkan alert jika ada error
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Peringatan"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}
