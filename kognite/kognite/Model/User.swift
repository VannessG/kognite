//
//  User.swift
//  kognite-se
//
//  Created by Vanness Aurelius Gunawan on 12/05/26.
//

import Foundation
import FirebaseFirestore

// Merepresentasikan entitas profil pengguna untuk menyimpan identitas dasar dan akumulasi statistik produktivitas secara persisten
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var email: String
    var currentStreak: Int
    var totalCompletedTasks: Int?
}
