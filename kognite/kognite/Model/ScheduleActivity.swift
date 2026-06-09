//
//  ScheduleActivity.swift
//  kognite
//
//  Created by Lemuel on 01/06/26.
//

import Foundation
import FirebaseFirestore

// Mewakili satu blok waktu rutinitas dalam jadwal harian agar sistem dapat memvalidasi dan mencegah terjadinya bentrok waktu
struct ScheduleActivity: Identifiable, Codable {
    @DocumentID var id: String?
    var scheduleId: String
    var iconName: String
    var startTime: String
    var endTime: String
    var description: String
    var isCompleted: Bool
    var isValidToday: Bool
}
