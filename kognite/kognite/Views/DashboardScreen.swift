//
//  DashboardScreen.swift
//  kognite
//
//  Created by Lemuel on 01/06/26.
//

import SwiftUI

// Menampilkan ringkasan produktivitas harian pengguna, jadwal aktivitas terdekat, dan daftar tugas aktif dalam satu halaman utama yang terpadu
struct DashboardScreen: View {
    @StateObject var viewModel = DashboardViewModel()
    @StateObject var activityVM = ActivityListViewModel()
    
    // State lokal untuk mengontrol form tambah aktivitas dari shortcut ikon di dasbor
    @State private var showingAddActivity = false
    @State private var selectedIcon = ""
    @State private var selectedTitle = ""
    @State private var activityDesc = ""
    @State private var activityStart = Date()
    @State private var activityEnd = Date()
    
    // State lokal untuk menampilkan pesan error validasi waktu pada form tambah aktivitas
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // State lokal untuk menahan referensi tugas yang akan dikonfirmasi sebelum ditandai selesai
    @State private var showTaskCompletionAlert = false
    @State private var taskToComplete: kognite.Task?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // Bagian sapaan personal yang menampilkan nama pengguna aktif di bagian atas dasbor
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Welcome Back,")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text(viewModel.currentUserDisplayName.capitalized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Bagian progress bar yang merepresentasikan secara visual persentase tugas harian yang telah diselesaikan
                    VStack(alignment: .leading, spacing: 8) {
                        let currentProgress = viewModel.calculateProgress()
                        let progressPercentage = Int(currentProgress * 100)
                        
                        HStack {
                            Text("Today's Progress")
                                .font(.headline)
                            Spacer()
                            Text("\(progressPercentage)%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                        }
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(height: 10)
                                    .foregroundColor(Color.gray.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: geometry.size.width * CGFloat(currentProgress), height: 10)
                                    .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                                    .animation(.easeInOut(duration: 0.5), value: currentProgress)
                            }
                        }
                        .frame(height: 10)
                        
                        let completedCount = viewModel.tasks.filter { $0.isCompleted }.count
                        Text("\(completedCount) of \(viewModel.tasks.count) completed")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Kartu jadwal berikutnya yang menampilkan aktivitas terdekat yang belum berakhir, atau pesan selesai jika tidak ada aktivitas tersisa
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: activityVM.getNextActivity()?.iconName ?? "calendar")
                            Text("Schedule")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white.opacity(0.8))
                        
                        if let nextActivity = activityVM.getNextActivity() {
                            Text(activityVM.getActivityName(icon: nextActivity.iconName))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(nextActivity.description.isEmpty ? "No description" : nextActivity.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("\(nextActivity.startTime) - \(nextActivity.endTime)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        } else {
                            Text("All Done!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("No upcoming activities for today.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.42, green: 0.72, blue: 0.5))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Bagian shortcut ikon aktivitas yang memungkinkan pengguna menambah rutinitas harian dengan cepat tanpa harus masuk ke halaman manajemen
                    VStack {
                        HStack {
                            Text("Activities")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            NavigationLink(destination: ManageActivityScreen(viewModel: activityVM)) {
                                Text("Manage")
                                    .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ActivityIcon(icon: "sun.max.fill", title: "Wake up", color: .green).onTapGesture { openAddActivityForm(icon: "sun.max.fill", title: "Wake up") }
                                ActivityIcon(icon: "drop.fill", title: "Wash up", color: .blue).onTapGesture { openAddActivityForm(icon: "drop.fill", title: "Wash up") }
                                ActivityIcon(icon: "hands.sparkles.fill", title: "Prayer", color: .purple).onTapGesture { openAddActivityForm(icon: "hands.sparkles.fill", title: "Prayer") }
                                ActivityIcon(icon: "fork.knife", title: "Eat", color: .orange).onTapGesture { openAddActivityForm(icon: "fork.knife", title: "Eat") }
                                ActivityIcon(icon: "book.fill", title: "Study", color: .red).onTapGesture { openAddActivityForm(icon: "book.fill", title: "Study") }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Bagian daftar tugas aktif yang belum selesai beserta tombol penyelesaian dan tautan ke halaman manajemen tugas lengkap
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Upcoming Deadlines")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            NavigationLink(destination: ManageTaskScreen(viewModel: viewModel)) {
                                Text("Manage")
                                    .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                            }
                        }
                        .padding(.horizontal)
                        
                        let incompleteTasks = viewModel.tasks.filter { !$0.isCompleted }
                        
                        if incompleteTasks.isEmpty {
                            Text("No active tasks available. Add some!")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        } else {
                            ForEach(incompleteTasks) { task in
                                HStack {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: 4, height: 40)
                                        .cornerRadius(2)
                                    VStack(alignment: .leading) {
                                        Text(task.title).font(.headline)
                                        HStack {
                                            Image(systemName: "calendar")
                                            Text(task.deadline)
                                        }.font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    
                                    Button(action: {
                                        taskToComplete = task
                                        showTaskCompletionAlert = true
                                    }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.gray.opacity(0.3))
                                            .font(.title2)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all))
            .toolbar(.hidden, for: .navigationBar)
            
            // Alert konfirmasi sebelum menandai tugas sebagai selesai untuk mencegah penyelesaian yang tidak disengaja
            .alert(isPresented: $showTaskCompletionAlert) {
                Alert(
                    title: Text("Konfirmasi"),
                    message: Text("Apakah tugas anda sudah selesai?"),
                    primaryButton: .default(Text("Ya, Selesai")) {
                        if let task = taskToComplete {
                            viewModel.completeTask(task: task)
                        }
                    },
                    secondaryButton: .cancel(Text("Batal"))
                )
            }
            
            // Sheet tambah aktivitas yang muncul dari shortcut ikon dasbor dengan validasi waktu sebelum data disimpan
            .sheet(isPresented: $showingAddActivity) {
                VStack(spacing: 20) {
                    Text("Add Activity").font(.title2).fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Image(systemName: selectedIcon).foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45)).font(.title2)
                        Text(selectedTitle).font(.headline)
                        Spacer()
                    }
                    
                    TextField("Description (Optional)", text: $activityDesc)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    
                    DatePicker("Start time", selection: $activityStart, displayedComponents: .hourAndMinute).padding(.vertical, 5)
                    DatePicker("End time", selection: $activityEnd, displayedComponents: .hourAndMinute).padding(.vertical, 5)
                    
                    Spacer()
                    
                    Button(action: {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        let startStr = formatter.string(from: activityStart)
                        let endStr = formatter.string(from: activityEnd)
                        
                        let validation = activityVM.validateActivityTime(start: startStr, end: endStr)
                        if validation.0 {
                            activityVM.addActivity(icon: selectedIcon, title: selectedTitle, start: startStr, end: endStr, desc: activityDesc)
                            showingAddActivity = false
                        } else {
                            errorMessage = validation.1 ?? "Waktu tidak valid."
                            showErrorAlert = true
                        }
                    }) {
                        Text("Add Activity").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color(red: 0.35, green: 0.65, blue: 0.45)).cornerRadius(12)
                    }
                }
                .padding(25)
                .presentationDetents([.fraction(0.55)])
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Peringatan"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
            }
        }
        // Memuat data tugas dan aktivitas secara bersamaan saat halaman pertama kali muncul
        .onAppear {
            viewModel.loadDashboardData()
            activityVM.loadActivities()
        }
    }
    
    // Menyiapkan state form tambah aktivitas dengan ikon dan judul yang dipilih, lalu menampilkan sheet input kepada pengguna
    func openAddActivityForm(icon: String, title: String) {
        selectedIcon = icon
        selectedTitle = title
        activityStart = Date()
        activityEnd = Date()
        activityDesc = ""
        showingAddActivity = true
    }
}

// Menampilkan tombol ikon aktivitas berbentuk lingkaran berwarna dengan label teks di bawahnya untuk digunakan sebagai shortcut pada baris aktivitas dasbor
struct ActivityIcon: View {
    var icon: String; var title: String; var color: Color
    var body: some View {
        VStack {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 60, height: 60)
                Image(systemName: icon).foregroundColor(color).font(.title2)
            }
            Text(title).font(.caption).foregroundColor(.black)
        }
    }
}
