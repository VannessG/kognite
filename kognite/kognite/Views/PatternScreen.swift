//
//  PatternScreen.swift
//  kognite-se
//
//  Created by Davyne on 01/06/26.
//

import SwiftUI

// Menyediakan antarmuka visual permainan interaktif yang ramah sensori saat jeda belajar guna memfasilitasi transisi kognitif anak ADHD agar tetap terstimulasi secara terstruktur.
struct PatternScreen: View {
    @StateObject private var viewModel = PatternViewModel()
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    let tileColors: [Color] = [.red, .blue, .yellow, .green]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Memory Pattern")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(viewModel.message ?? "")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Score: \(viewModel.score)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(tileColors[index])
                        .frame(height: 130)
                        .opacity(viewModel.activeTileIndex == index ? 1.0 : 0.4)
                        .scaleEffect(viewModel.activeTileIndex == index ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: viewModel.activeTileIndex)
                        .shadow(color: tileColors[index].opacity(0.4), radius: 5, y: 5)
                        .onTapGesture {
                            viewModel.onTileTapped(index: index)
                        }
                }
            }
            .padding(40)
            
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.startGame()
                }) {
                    Text("Start Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.35, green: 0.65, blue: 0.45))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    viewModel.replaySequence()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all))
    }
}
