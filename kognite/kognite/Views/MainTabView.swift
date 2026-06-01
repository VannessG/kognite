//
//  MainTabView.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            DashboardScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            FocusTimerScreen()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
            
            RewardScreen()
                .tabItem {
                    Label("Rewards", systemImage: "star.fill")
                }
            
            ProfileView(authViewModel: authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(.green)
    }
}
#Preview {
    MainTabView(authViewModel: AuthViewModel())
}
