//
//  Reward.swift
//  kognite-se
//
//  Created by Davyne on 01/06/26.
//

import Foundation
import FirebaseFirestore

// Menentukan kriteria pencapaian dan status keterbukaan hadiah untuk memberikan sistem gamifikasi dan motivasi kepada pengguna
struct Reward: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var iconName: String
    var milestone: Int
    var description: String
    var streakRequired: Int
    var dateAchieved: String
    var isUnlocked: Bool
}