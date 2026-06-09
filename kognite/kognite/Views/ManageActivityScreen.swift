//
//  ManageActivityScreen.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import SwiftUI

struct ManageActivityScreen: View {
    @ObservedObject var viewModel: ActivityListViewModel
    
    // State untuk mengelola Edit
    @State private var activityToEdit: ScheduleActivity?
    
    // State untuk mengelola Alert Delete
    @State private var showingDeleteAlert = false
    @State private var activityToDelete: ScheduleActivity?

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all)
            
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
                            
                            // Edit Button
                            Button(action: {
                                activityToEdit = activity
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .padding(.trailing, 8)
                            
                            // Delete Button
                            Button(action: {
                                // PERUBAHAN: Set state alert alih-alih langsung menghapus
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
        .sheet(item: $activityToEdit) { activity in
            EditActivitySheet(viewModel: viewModel, activity: activity)
        }
        // TAMBAHAN: Alert Konfirmasi Delete
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

// MARK: - Edit Activity Sheet
struct EditActivitySheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ActivityListViewModel
    
    let activity: ScheduleActivity
    
    @State private var desc: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var errorMessage: String?
    
    init(viewModel: ActivityListViewModel, activity: ScheduleActivity) {
        self.viewModel = viewModel
        self.activity = activity
        
        // Inisialisasi state awal dengan data aktivitas yang dipilih
        _desc = State(initialValue: activity.description)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        // Convert string waktu (misal "08:00") ke tipe Date agar bisa dipakai di DatePicker
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
    
    private func saveActivity() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let startStr = formatter.string(from: startTime)
        let endStr = formatter.string(from: endTime)
        
        // Validasi waktu menggunakan logic di ViewModel, tapi mengecualikan ID aktivitas ini sendiri agar tidak dianggap bertabrakan dengan jadwalnya sendiri
        let (isValid, errorMsg) = viewModel.validateActivityTime(start: startStr, end: endStr, excludeId: activity.id)
        
        if isValid {
            // Update & tutup sheet jika tervalidasi sukses
            viewModel.updateActivity(activity, start: startStr, end: endStr, desc: desc)
            presentationMode.wrappedValue.dismiss()
        } else {
            errorMessage = errorMsg
        }
    }
}
