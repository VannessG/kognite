//
//  Task.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import Foundation
import FirebaseFirestore

// Menyimpan detail informasi tugas dan tenggat waktu spesifik yang harus dikerjakan oleh pengguna pada jadwal tertentu
struct Task: Identifiable, Codable {
    @DocumentID var id: String?
    var scheduleId: String
    var title: String
    var deadline: String
    var description: String?
    var isCompleted: Bool
    var color: String
}
