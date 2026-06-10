//
//  ManageActivityScreen.swift
//  kognite
//
//  Created by Lemuel on 01/06/26.
//

import SwiftUI

// Menampilkan daftar lengkap aktivitas rutinitas pengguna beserta opsi edit dan hapus untuk mengelola jadwal harian secara penuh
struct ManageActivityScreen: View {
    @ObservedObject var viewModel: ActivityListViewModel
    
    // State lokal untuk menyimpan referensi aktivitas yang akan diedit melalui sheet
    @State private var activityToEdit: ScheduleActivity?
    
    // State lokal untuk menahan referensi aktivitas yang akan dihapus sampai konfirmasi diberikan
    @State private var showingDeleteAlert = false
    @State private var activityToDelete: ScheduleActivity?

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all)
            
            // Menampilkan tampilan kosong dengan instruksi jika pengguna belum memiliki aktivitas sama sekali
            if viewModel.activities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No activities available.")
                        .font(.title3).fontWeight(.semibold).foregroundColor(.gray)
                    Text("Please add some activities from your dashboard.")
                        .font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
                }
            } else {
                // Menampilkan daftar seluruh aktivitas yang sudah tersusun kronologis beserta tombol edit dan hapus di setiap baris
                List {
                    ForEach(viewModel.activities) { activity in
                        HStack {
                            Image(systemName: activity.iconName)
                                .foregroundColor(Color(red: 0.35, green: 0.65, blue: 0.45))
                                .font(.title3)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(viewModel.getActivityName(icon: activity.iconName))
                                    .font(.headline)
                                Text("\(activity.startTime) - \(activity.endTime)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                if !activity.description.isEmpty {
                                    Text(activity.description)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            
                            Button(action: {
                                activityToEdit = activity
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 8)
                            
                            Button(action: {
                                activityToDelete = activity
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.vertical, 5)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Manage Activities")
        .navigationBarTitleDisplayMode(.inline)
        // Membuka sheet edit aktivitas saat pengguna memilih ikon pensil pada salah satu baris aktivitas
        .sheet(item: $activityToEdit) { activity in
            EditActivitySheet(viewModel: viewModel, activity: activity)
        }
        // Alert konfirmasi penghapusan untuk mencegah pengguna menghapus aktivitas secara tidak sengaja
        .alert("Konfirmasi Hapus", isPresented: $showingDeleteAlert) {
            Button("Batal", role: .cancel) {
                activityToDelete = nil
            }
            Button("Hapus", role: .destructive) {
                if let id = activityToDelete?.id {
                    viewModel.deleteActivity(id: id)
                }
                activityToDelete = nil
            }
        } message: {
            Text("Apakah anda yakin ingin menghapus aktivitas ini?")
        }
    }
}

// Menyediakan form edit waktu dan deskripsi aktivitas yang sudah ada, dengan validasi bentrok jadwal sebelum perubahan disimpan
struct EditActivitySheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ActivityListViewModel
    
    let activity: ScheduleActivity
    
    @State private var desc: String
    @State private var startTime: Date
    @State private var endTime: Date
    // State untuk menyimpan pesan error validasi waktu yang ditampilkan langsung di dalam form
    @State private var errorMessage: String?
    
    // Menginisialisasi state form dengan data aktivitas yang sudah ada agar pengguna bisa melihat nilai sebelumnya saat membuka sheet edit
    init(viewModel: ActivityListViewModel, activity: ScheduleActivity) {
        self.viewModel = viewModel
        self.activity = activity
        
        _desc = State(initialValue: activity.description)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        _startTime = State(initialValue: formatter.date(from: activity.startTime) ?? Date())
        _endTime = State(initialValue: formatter.date(from: activity.endTime) ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Details")) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    TextField("Description (Optional)", text: $desc)
                }
                
                // Menampilkan pesan error validasi waktu secara inline jika jadwal yang baru bertabrakan dengan aktivitas lain
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveActivity()
                }
            )
        }
    }
    
    // Memvalidasi waktu yang diubah terhadap jadwal aktivitas lain sebelum menyimpan perubahan dan menutup sheet
    private func saveActivity() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let startStr = formatter.string(from: startTime)
        let endStr = formatter.string(from: endTime)
        
        let (isValid, errorMsg) = viewModel.validateActivityTime(start: startStr, end: endStr, excludeId: activity.id)
        
        if isValid {
            viewModel.updateActivity(activity, start: startStr, end: endStr, desc: desc)
            presentationMode.wrappedValue.dismiss()
        } else {
            errorMessage = errorMsg
        }
    }
}
