//
//  ManageTaskScreen.swift
//  kognite
//
//  Created by Lemuel on 01/06/26.
//

import SwiftUI

// Mendefinisikan jenis aksi yang sedang menunggu verifikasi password agar satu alur autentikasi dapat melayani baik penghapusan maupun pengeditan tugas
enum TaskAction {
    case delete
    case edit
}

// Menampilkan daftar tugas aktif dan selesai secara terpisah, dengan perlindungan Parental Lock untuk aksi sensitif seperti edit dan hapus
struct ManageTaskScreen: View {
    @ObservedObject var viewModel: DashboardViewModel

    // State lokal untuk mengontrol visibilitas popup tambah tugas beserta isian datanya
    @State private var showingAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDesc = ""
    @State private var newTaskDeadline = Date()

    // State lokal untuk menahan referensi tugas yang menunggu konfirmasi penyelesaian
    @State private var showCompletionWarning = false
    @State private var taskToComplete: kognite.Task?

    // State lokal untuk alur verifikasi password Parental Lock sebelum aksi sensitif dieksekusi
    @State private var showPasswordPrompt = false
    @State private var enteredPassword = ""
    @State private var showAuthError = false
    @State private var authErrorMessage = ""
    
    // State lokal untuk menyimpan referensi tugas yang sedang diproses beserta jenis aksinya
    @State private var taskToModify: kognite.Task?
    @State private var pendingAction: TaskAction = .delete

    // State lokal untuk mengontrol visibilitas popup edit tugas beserta isian datanya
    @State private var showingEditTask = false
    @State private var editTaskTitle = ""
    @State private var editTaskDesc = ""
    @State private var editTaskDeadline = Date()

    var body: some View {
        ZStack {
            ZStack {
                Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        incompleteSection
                        completedSection
                    }
                    .padding(.vertical)
                    .padding(.bottom, 80)
                }

                // Floating action button di pojok kanan bawah untuk membuka popup tambah tugas baru
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
            // Menerapkan efek blur pada konten di belakang saat popup tambah atau edit tugas sedang terbuka
            .blur(radius: showingAddTask || showingEditTask ? 5 : 0)
            
            // Overlay gelap semi-transparan yang menutup popup saat pengguna mengetuk area di luar form
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
            if showingAddTask { addTaskPopUp }
            if showingEditTask { editTaskPopUp }
        }
        .navigationTitle("Manage Tasks")
        .navigationBarTitleDisplayMode(.inline)
        
        // Alert konfirmasi sebelum menandai tugas sebagai selesai untuk mencegah penyelesaian yang tidak disengaja
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
        
        // Alert Parental Lock yang meminta password akun sebelum aksi edit atau hapus dieksekusi
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
        
        // Alert yang menampilkan pesan kegagalan verifikasi jika password yang dimasukkan salah
        .alert("Verifikasi Gagal", isPresented: $showAuthError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authErrorMessage)
        }
    }

    // Menampilkan bagian daftar tugas yang belum selesai, atau pesan kosong jika semua tugas sudah diselesaikan
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

    // Menampilkan bagian daftar tugas yang sudah selesai hanya jika ada setidaknya satu tugas yang berhasil diselesaikan
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

    // Merender satu baris tugas dengan tampilan visual yang berbeda antara tugas aktif dan selesai, beserta tombol aksi yang relevan untuk setiap statusnya
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
        
            if !task.isCompleted {
                Button(action: {
                    taskToModify = task
                    prepareEditSheet()
                    withAnimation { showingEditTask = true }
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .padding(.leading, 5)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
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

    // Mengeksekusi aksi yang tertunda (hapus atau edit) setelah verifikasi password berhasil, atau menampilkan pesan error jika autentikasi gagal
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
                        if let task = self.taskToModify {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "dd MMM yyyy, HH:mm"
                            
                            self.viewModel.updateTask(
                                id: task.id ?? "",
                                title: self.editTaskTitle,
                                deadline: formatter.string(from: self.editTaskDeadline),
                                description: self.editTaskDesc
                            )
                        }
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
    
    // Mengisi state form edit dengan data tugas yang dipilih agar pengguna melihat nilai sebelumnya saat popup terbuka
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
    
    // Popup form tambah tugas baru yang muncul di tengah layar dengan overlay blur, berisi field judul, deskripsi, dan deadline
    private var addTaskPopUp: some View {
        ZStack {
            
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
                    
                    // Tombol Add dinonaktifkan selama judul masih kosong untuk mencegah penyimpanan tugas tanpa nama
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
    
    // Popup form edit tugas yang muncul di tengah layar dengan overlay blur, menampilkan data tugas yang ada dan memerlukan verifikasi password sebelum perubahan disimpan
    private var editTaskPopUp: some View {
        ZStack {
            
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
                    
                    // Tombol Save memicu Parental Lock sebelum perubahan benar-benar diterapkan ke data
                    Button(action: {
                        pendingAction = .edit
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
