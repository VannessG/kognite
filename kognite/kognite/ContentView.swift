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
                MainTabView(authViewModel: authViewModel)
            } else {
                LoginScreen(viewModel: authViewModel)
            }
        }
        .onAppear {
            authViewModel.checkExistingSession()
        }
    }
}

#Preview {
    ContentView()
}
