//
//  Schedule.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
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
