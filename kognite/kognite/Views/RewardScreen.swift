//
//  RewardScreen.swift
//  kognite-se
//
//  Created by Davyne on 01/06/26.
//

import SwiftUI

struct RewardScreen: View {
    @StateObject private var viewModel = RewardViewModel()
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.rewards) { reward in
                        VStack(spacing: 12) {
                            Image(systemName: reward.iconName)
                                .font(.system(size: 40))
                                .foregroundColor(reward.isUnlocked ? Color(red: 0.35, green: 0.65, blue: 0.45) : .gray.opacity(0.3))
                            
                            Text(reward.title)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text(reward.description)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                        .opacity(reward.isUnlocked ? 1.0 : 0.6)
                    }
                }
                .padding(20)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all))
            .navigationTitle("Achievements")
            .onAppear {
                viewModel.loadRewards()
            }
        }
    }
}
