//
//  ManageTaskScreen.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import SwiftUI

// Menentukan aksi yang tertunda setelah verifikasi password
enum TaskAction {
    case delete
    case edit
}

struct ManageTaskScreen: View {
    // Menerima instance viewModel yang sama dari Dashboard
    @ObservedObject var viewModel: DashboardViewModel

    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDesc = ""
    @State private var newTaskDeadline = Date()

    // States untuk Peringatan 'Done'
    @State private var showCompletionWarning = false
    @State private var taskToComplete: kognite.Task?

    // States untuk Keamanan (Edit & Delete)
    @State private var showPasswordPrompt = false
    @State private var enteredPassword = ""
    @State private var showAuthError = false
    @State private var authErrorMessage = ""
    
    @State private var taskToModify: kognite.Task?
    @State private var pendingAction: TaskAction = .delete

    // States untuk Form Edit
    @State private var showingEditTask = false
    @State private var editTaskTitle = ""
    @State private var editTaskDesc = ""
    @State private var editTaskDeadline = Date()

    var body: some View {
        ZStack {
            // --- KONTEN UTAMA (YANG AKAN DI-BLUR) ---
            ZStack {
                // 1. Background
                Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all)

                // 2. Konten Utama
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        incompleteSection
                        completedSection
                    }
                    .padding(.vertical)
                    .padding(.bottom, 80)
                }

                // 3. Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingAddTask = true
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(red: 0.35, green: 0.65, blue: 0.45))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
            // MODIFIER BLUR DIPINDAH KESINI (Hanya berlaku untuk konten di atas)
            .blur(radius: showingAddTask || showingEditTask ? 5 : 0)
            
            // --- LAPISAN POP UP (TIDAK TERKENA BLUR) ---
            
            // 4. Lapisan Gelap Pembatas
            if showingAddTask || showingEditTask {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingAddTask = false
                            showingEditTask = false
                        }
                    }
            }
            
            // 5. Form Pop Up
            if showingAddTask { addTaskPopUp }
            if showingEditTask { editTaskPopUp }
        }
        .navigationTitle("Manage Tasks")
        .navigationBarTitleDisplayMode(.inline)
        
        // Alert Peringatan Penyelesaian Task
        .alert("Konfirmasi Penyelesaian", isPresented: $showCompletionWarning) {
            Button("Batal", role: .cancel) { taskToComplete = nil }
            Button("Yakin") {
                if let task = taskToComplete {
                    viewModel.completeTask(task: task)
                }
                taskToComplete = nil
            }
        } message: {
            Text("Apakah anda yakin sudah menyelesaikan tugas ini?")
        }
        
        // Alert Meminta Password untuk Edit/Delete
        .alert("Parental Lock", isPresented: $showPasswordPrompt) {
            SecureField("Masukkan Password Akun", text: $enteredPassword)
            Button("Batal", role: .cancel) {
                enteredPassword = ""
                taskToModify = nil
            }
            Button("Lanjutkan") {
                verifyPasswordAndExecute()
            }
        } message: {
            Text("Masukkan password akun Anda untuk melanjutkan aksi ini.")
        }
        
        // Alert Jika Password Salah
        .alert("Verifikasi Gagal", isPresented: $showAuthError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authErrorMessage)
        }
    }

    private var incompleteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Incomplete Tasks")
                .font(.headline)
                .padding(.horizontal)
            
            let incompleteTasks = viewModel.tasks.filter { !$0.isCompleted }
            if incompleteTasks.isEmpty {
                Text("Semua tugas telah selesai!")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                ForEach(incompleteTasks) { task in
                    taskRow(task: task)
                }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            let completedTasks = viewModel.tasks.filter { $0.isCompleted }
            if !completedTasks.isEmpty {
                Text("Completed")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(completedTasks) { task in
                    taskRow(task: task)
                }
            }
        }
    }

    // Desain Row
    private func taskRow(task: kognite.Task) -> some View {
        HStack {
            Rectangle()
                .fill(task.isCompleted ? Color.gray : Color.blue)
                .frame(width: 4, height: 40)
                .cornerRadius(2)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted, color: .gray)
                    .foregroundColor(task.isCompleted ? .gray : .black)
                
                HStack {
                    Image(systemName: "calendar")
                    Text(task.deadline)
                }.font(.caption).foregroundColor(.gray)
                
                if let desc = task.description, !desc.isEmpty {
                    Text(desc).font(.caption2).foregroundColor(.gray)
                }
            }
            Spacer()
            
            // Tombol Done (Memicu Peringatan)
            if !task.isCompleted {
                Button(action: {
                    taskToComplete = task
                    showCompletionWarning = true
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.gray.opacity(0.3))
                        .font(.title2)
                }
                .buttonStyle(BorderlessButtonStyle())
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.green)
                    .font(.title2)
            }
        
            // Tombol Edit (Langsung Buka Form)
            if !task.isCompleted {
                Button(action: {
                    taskToModify = task
                    prepareEditSheet() // Siapkan data ke dalam form
                    withAnimation { showingEditTask = true } // Langsung tampilkan form
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .padding(.leading, 5)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // Tombol Delete (Memicu Password)
            Button(action: {
                taskToModify = task
                pendingAction = .delete
                showPasswordPrompt = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(.leading, 5)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }

    private func verifyPasswordAndExecute() {
        viewModel.verifyPassword(password: enteredPassword) { success, message in
            self.enteredPassword = ""
            
            if success {
                withAnimation {
                    if self.pendingAction == .delete {
                        if let id = self.taskToModify?.id {
                            self.viewModel.deleteTask(id: id)
                        }
                    } else if self.pendingAction == .edit {
                        // LOGIKA SIMPAN DI SINI
                        if let task = self.taskToModify {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "dd MMM yyyy, HH:mm"
                            
                            // Memanggil updateTask ke ViewModel
                            self.viewModel.updateTask(
                                id: task.id ?? "",
                                title: self.editTaskTitle,
                                deadline: formatter.string(from: self.editTaskDeadline),
                                description: self.editTaskDesc
                            )
                        }
                        // Menutup form edit setelah password benar & data terupdate
                        self.showingEditTask = false
                    }
                    self.taskToModify = nil
                }
            } else {
                self.authErrorMessage = message
                self.showAuthError = true
            }
        }
    }
    
    // Mengisi form edit dengan data dari task yang dipilih
    private func prepareEditSheet() {
        guard let task = taskToModify else { return }
        editTaskTitle = task.title
        editTaskDesc = task.description ?? ""
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        if let date = formatter.date(from: task.deadline) {
            editTaskDeadline = date
        } else {
            editTaskDeadline = Date()
        }
    }

    // MARK: - Custom Pop-Ups
    
    private var addTaskPopUp: some View {
        ZStack {
            // Hapus background hitam opacity 0.4 di sini, karena sudah ada di luar (di lapisan 4)
            
            VStack(spacing: 25) {
                Text("New Task").font(.title2).bold()
                
                VStack(spacing: 15) {
                    TextField("Task Title", text: $newTaskTitle)
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    
                    TextField("Description (Optional)", text: $newTaskDesc)
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    
                    DatePicker("Deadline", selection: $newTaskDeadline, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal, 5)
                        .padding(.vertical, 5)
                }
                
                HStack(spacing: 15) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { showingAddTask = false }
                    }) {
                        Text("Cancel").bold().frame(maxWidth: .infinity).padding().background(Color.gray.opacity(0.15)).foregroundColor(.gray).cornerRadius(12)
                    }
                    
                    Button(action: {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd MMM yyyy, HH:mm"
                        
                        viewModel.addTask(
                            title: newTaskTitle,
                            deadline: formatter.string(from: newTaskDeadline),
                            description: newTaskDesc,
                            color: "blue"
                        )
                        newTaskTitle = ""
                        newTaskDesc = ""
                        newTaskDeadline = Date()
                        withAnimation(.easeInOut(duration: 0.2)) { showingAddTask = false }
                    }) {
                        Text("Add").bold().frame(maxWidth: .infinity).padding().background(Color(red: 0.35, green: 0.65, blue: 0.45)).foregroundColor(.white).cornerRadius(12)
                    }
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(25).background(Color.white).cornerRadius(24).shadow(radius: 20).padding(.horizontal, 30)
        }
    }
    
    private var editTaskPopUp: some View {
        ZStack {
            // Hapus background hitam opacity 0.4 di sini juga
            
            VStack(spacing: 25) {
                Text("Edit Task Info").font(.title2).bold()
                
                VStack(spacing: 15) {
                    TextField("Task Title", text: $editTaskTitle)
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    
                    TextField("Description (Optional)", text: $editTaskDesc)
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                    
                    DatePicker("Deadline", selection: $editTaskDeadline, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal, 5)
                        .padding(.vertical, 5)
                }
                
                HStack(spacing: 15) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { showingEditTask = false }
                    }) {
                        Text("Cancel").bold().frame(maxWidth: .infinity).padding().background(Color.gray.opacity(0.15)).foregroundColor(.gray).cornerRadius(12)
                    }
                    
                    Button(action: {
                        // 1. Set action ke .edit
                        pendingAction = .edit
                        // 2. Minta password lagi
                        showPasswordPrompt = true
                    }) {
                        Text("Save")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.35, green: 0.65, blue: 0.45))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(editTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .disabled(editTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(25).background(Color.white).cornerRadius(24).shadow(radius: 20).padding(.horizontal, 30)
        }
    }
}
