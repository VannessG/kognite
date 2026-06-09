//
//  ContentView.swift
//  kognite
//
//  Created by Vanness Aurelius Gunawan on 15/05/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Mengarahkan ke TabView Utama ketika berhasil Login
                MainTabView(authViewModel: authViewModel)
            } else {
                LoginScreen(viewModel: authViewModel)
            }
        }
        .onAppear {
            // Cek sesi Firebase saat aplikasi baru dibuka
            if Auth.auth().currentUser != nil {
                authViewModel.isAuthenticated = true
            }
        }
    }
}

#Preview {
    ContentView()
}

