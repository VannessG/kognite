//
//  FocusTimerScreen.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import SwiftUI

// Menentukan aksi apa yang akan dijalankan setelah password benar
enum PasswordAction {
    case skipTimer
    case saveSettings
}

// Menampilkan halaman timer dengan animasi pada timernya
struct FocusTimerScreen: View {
    @StateObject private var viewModel = FocusTimerViewModel()
    
    @State private var navigateToPattern = false
    @State private var showSettings = false
    @State private var showAnimationPicker = false
    
    @State private var showPasswordPrompt = false
    @State private var enteredPassword = ""
    @State private var showAuthError = false
    @State private var authErrorMessage = ""
    @State private var pendingAction: PasswordAction = .skipTimer
    
    @State private var tempFocus = 25
    @State private var tempShort = 5
    @State private var tempLong = 15
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    Text(viewModel.currentMode.rawValue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.35, green: 0.65, blue: 0.45).opacity(0.1))
                        .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                        .cornerRadius(20)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 280, height: 280)
                        
                        Circle()
                            .stroke(lineWidth: 25)
                            .foregroundColor(Color.gray.opacity(0.2))
                        
                        Circle()
                            .trim(from: 1.0 - viewModel.progress, to: 1.0)
                            .stroke(style: StrokeStyle(lineWidth: 25, lineCap: .round))
                            .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                            .rotationEffect(Angle(degrees: -90))
                            .animation(.linear(duration: 1.0), value: viewModel.progress)
                        
                        VStack {
                            if let lottieName = viewModel.selectedAnimation.lottieFileName {
                                LottieView(animationName: lottieName, isPlaying: viewModel.isPlaying)
                                    .frame(width: 150, height: 150)
                                    .scaleEffect({
                                        switch viewModel.selectedAnimation {
                                        case .sloth:   return 0.45
                                        case .bear:    return 0.2
                                        case .avocado: return 0.5
                                        case .panda:   return 0.25
                                        case .cat:     return 0.85
                                        }
                                    }())
                                    .id(viewModel.selectedAnimation.rawValue)
                            }
                            
                            Text(viewModel.timeString)
                                .font(.system(size: 40, weight: .bold))
                                .monospacedDigit()
                                .shadow(color: .white.opacity(0.5), radius: 2)
                        }
                        .frame(width: 250, height: 250)
                    }
                    .frame(width: 300, height: 300)
                    .padding()
                    
                    Spacer()
                    
                    HStack(spacing: 15) {
                        if viewModel.currentMode != .focus {
                            Button(action: { navigateToPattern = true }) {
                                HStack {
                                    Image(systemName: "gamecontroller.fill")
                                    Text("Play Mini Game")
                                }
                                .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.35, green: 0.65, blue: 0.45), lineWidth: 1))
                            }
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAnimationPicker = true
                            }
                        }) {
                            Text("Choose Animation")
                                .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.35, green: 0.65, blue: 0.45), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal)
                    .navigationDestination(isPresented: $navigateToPattern) {
                        PatternScreen()
                    }
                    
                    HStack(spacing: 30) {
                        Button(action: { viewModel.resetTimer() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title)
                                .foregroundColor(.gray)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        
                        Button(action: {
                            withAnimation { viewModel.toggleTimer() }
                        }) {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color(red: 0.35, green: 0.65, blue: 0.45))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            pendingAction = .skipTimer
                            showPasswordPrompt = true
                        }) {
                            Image(systemName: "forward.end.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                    .padding(.top, 20)
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text("Focus").font(.caption).foregroundColor(viewModel.currentMode == .focus ? .black : .gray)
                            Text("\(viewModel.focusMinutes)m").font(.headline).foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                        }
                        VStack {
                            Text("Short Break").font(.caption).foregroundColor(viewModel.currentMode == .shortBreak ? .black : .gray)
                            Text("\(viewModel.shortBreakMinutes)m").font(.headline).foregroundColor(.orange)
                        }
                        VStack {
                            Text("Long Break").font(.caption).foregroundColor(viewModel.currentMode == .longBreak ? .black : .gray)
                            Text("\(viewModel.longBreakMinutes)m").font(.headline).foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                    .padding()
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all))
                
                .onChange(of: viewModel.currentMode) { oldValue, newValue in
                    if newValue == .focus {
                        navigateToPattern = false
                    }
                }
                
                .navigationTitle("Focus Timer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                tempFocus = viewModel.focusMinutes
                                tempShort = viewModel.shortBreakMinutes
                                tempLong = viewModel.longBreakMinutes
                                showSettings = true
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                        }
                    }
                }
            }
            .blur(radius: showSettings || showAnimationPicker ? 5 : 0)
            
            if showSettings {
                ZStack {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all).onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { showSettings = false }
                    }
                    
                    VStack(spacing: 25) {
                        Text("Timer Settings").font(.title2).bold()
                        
                        VStack(spacing: 15) {
                            HStack {
                                Text("Focus Time").font(.headline).foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                                Spacer()
                                HStack(spacing: 15) {
                                    Button(action: { if tempFocus > 1 { tempFocus -= 1 } }) {
                                        Image(systemName: "minus.circle.fill").font(.title2).foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45).opacity(tempFocus > 1 ? 1.0 : 0.3))
                                    }
                                    Text("\(tempFocus)m").font(.headline).frame(width: 45)
                                    Button(action: { if tempFocus < 120 { tempFocus += 1 } }) {
                                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45).opacity(tempFocus < 120 ? 1.0 : 0.3))
                                    }
                                }
                            }.padding(.vertical, 5)
                            
                            HStack {
                                Text("Short Break").font(.headline).foregroundColor(.orange)
                                Spacer()
                                HStack(spacing: 15) {
                                    Button(action: { if tempShort > 1 { tempShort -= 1 } }) {
                                        Image(systemName: "minus.circle.fill").font(.title2).foregroundColor(Color.orange.opacity(tempShort > 1 ? 1.0 : 0.3))
                                    }
                                    Text("\(tempShort)m").font(.headline).frame(width: 45)
                                    Button(action: { if tempShort < 30 { tempShort += 1 } }) {
                                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(Color.orange.opacity(tempShort < 30 ? 1.0 : 0.3))
                                    }
                                }
                            }.padding(.vertical, 5)
                            
                            HStack {
                                Text("Long Break").font(.headline).foregroundColor(.blue)
                                Spacer()
                                HStack(spacing: 15) {
                                    Button(action: { if tempLong > 1 { tempLong -= 1 } }) {
                                        Image(systemName: "minus.circle.fill").font(.title2).foregroundColor(Color.blue.opacity(tempLong > 1 ? 1.0 : 0.3))
                                    }
                                    Text("\(tempLong)m").font(.headline).frame(width: 45)
                                    Button(action: { if tempLong < 60 { tempLong += 1 } }) {
                                        Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(Color.blue.opacity(tempLong < 60 ? 1.0 : 0.3))
                                    }
                                }
                            }.padding(.vertical, 5)
                        }
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) { showSettings = false }
                            }) {
                                Text("Cancel").bold().frame(maxWidth: .infinity).padding().background(Color.gray.opacity(0.15)).foregroundColor(.gray).cornerRadius(12)
                            }
                            
                            Button(action: {
                                pendingAction = .saveSettings
                                showPasswordPrompt = true
                            }) {
                                Text("Save").bold().frame(maxWidth: .infinity).padding().background(Color(red: 0.35, green: 0.65, blue: 0.45)).foregroundColor(.white).cornerRadius(12)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(25).background(Color.white).cornerRadius(24).shadow(radius: 20).padding(.horizontal, 30)
                }
            }
            if showAnimationPicker {
                ZStack {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all).onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { showAnimationPicker = false }
                    }
                    
                    VStack(spacing: 20) {
                        Text("Choose Animation").font(.title2).bold()
                        
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(AnimationChoice.allCases, id: \.self) { choice in
                                    Button(action: {
                                        viewModel.selectedAnimation = choice
                                        withAnimation(.easeInOut(duration: 0.2)) { showAnimationPicker = false }
                                    }) {
                                        HStack(spacing: 15) {
                                            if let lottieName = choice.lottieFileName {
                                                LottieView(animationName: lottieName, isPlaying: true)
                                                    .frame(width: 50, height: 50)
                                                    .scaleEffect({
                                                        switch choice {
                                                        case .sloth:   return 0.45 * 0.3
                                                        case .bear:    return 0.2 * 0.3
                                                        case .avocado: return 0.5 * 0.3
                                                        case .panda:   return 0.25 * 0.3
                                                        case .cat:     return 0.85 * 0.3
                                                        }
                                                    }())
                                                    .allowsHitTesting(false)
                                            }
                                            
                                            Text(choice.rawValue.capitalized)
                                                .font(.headline)
                                                .foregroundColor(viewModel.selectedAnimation == choice ? .white : .black)
                                            
                                            Spacer()
                                            
                                            if viewModel.selectedAnimation == choice {
                                                Image(systemName: "checkmark").font(.headline).foregroundColor(.white)
                                            }
                                        }
                                        .padding(.horizontal, 15).padding(.vertical, 8).frame(maxWidth: .infinity)
                                        .background(viewModel.selectedAnimation == choice ? Color(red: 0.35, green: 0.65, blue: 0.45) : Color.gray.opacity(0.08))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 400)
                    }
                    .padding(25).background(Color.white).cornerRadius(24).shadow(radius: 20).padding(.horizontal, 30)
                }
            }
        }
        
        .alert("Parental Lock", isPresented: $showPasswordPrompt) {
            SecureField("Enter Account Password", text: $enteredPassword)
            Button("Cancel", role: .cancel) { enteredPassword = "" }
            Button("Confirm") {
                viewModel.verifyPassword(password: enteredPassword) { success in
                    self.enteredPassword = ""
                    
                    if success {
                        withAnimation {
                            if self.pendingAction == .skipTimer {
                                self.viewModel.nextMode()
                            } else if self.pendingAction == .saveSettings {
                                self.viewModel.applySettings(focus: self.tempFocus, short: self.tempShort, long: self.tempLong)
                                self.showSettings = false
                            }
                        }
                    } else {
                        self.authErrorMessage = "Incorrect password. Please try again."
                        self.showAuthError = true
                    }
                }
            }
        } message: {
            Text("Enter your account password to proceed.")
        }
        
        .alert("Verification Failed", isPresented: $showAuthError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authErrorMessage)
        }
    }
}
