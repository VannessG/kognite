//
//  ProfileView.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import SwiftUI

// Menyediakan UI bagi user untuk meninjau identitas akun mereka saat ini serta memberikan akses yang aman untuk mengakhiri sesi aktif
struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showLogoutWarning = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all)
                
                VStack {
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                            .padding(.top, 10)
                        
                        VStack(spacing: 8) {
                            Text(authViewModel.currentUsername.capitalized)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text(authViewModel.currentUserEmail)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(30)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                    .padding(.horizontal, 25)
                    .padding(.top, 30)
                    
                    Spacer()
                    
                    Button(action: { showLogoutWarning = true }) {
                        Text("Logout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.85))
                            .cornerRadius(12)
                            .shadow(color: Color.red.opacity(0.3), radius: 5, y: 3)
                    }
                    .padding(.horizontal, 25).padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .alert("Konfirmasi Logout", isPresented: $showLogoutWarning) {
                Button("Batal", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("Apakah Anda yakin ingin keluar dari akun ini?")
            }
        }
    }
}
