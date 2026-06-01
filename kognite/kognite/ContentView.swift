//
//  ContentView.swift
//  kognite
//
//  Created by Vanness Aurelius Gunawan on 15/05/26.
//

import SwiftUI

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
            // PERBAIKAN: Menyerahkan tugas cek sesi ke ViewModel
            authViewModel.checkExistingSession()
        }
    }
}

#Preview {
    ContentView()
}
