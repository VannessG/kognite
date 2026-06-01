//
//  Schedule.swift
//  kognite
//
//  Created by Lemuel on 01/06/26.
//

import Foundation
import FirebaseFirestore

// Merangkum data harian pengguna sebagai wadah utama untuk mengkalkulasi persentase pencapaian dari total tugas yang ada
struct Schedule: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var date: String
    var totalTasks: Int
    var completedTasks: Int
    var progressPercentage: Float
}

