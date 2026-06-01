//
//  ActivityListViewModel.swift
//  kognite
//
//  Created by Lemuel on 01/06/26.
//

import Foundation
import Combine

@MainActor
class ActivityListViewModel: ObservableObject {
    @Published var activities: [ScheduleActivity] = []

    @Published var showingAddActivity = false
    @Published var selectedIcon = ""
    @Published var selectedTitle = ""
    @Published var activityDesc = ""
    @Published var activityStart = Date()
    @Published var activityEnd = Date()

    private var scheduleId: String

    init() {
        self.scheduleId = FirebaseManager.shared.getCurrentUserId() ?? "default_user"
    }

    func loadActivities() {
        Swift.Task {
            do {
                let fetched = try await FirebaseManager.shared.fetchActivities(scheduleId: scheduleId)
                self.activities = fetched.sorted { $0.startTime < $1.startTime }
            } catch {
                print("Gagal memuat aktivitas: \(error.localizedDescription)")
            }
        }
    }

    func getNextActivity() -> ScheduleActivity? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let now = formatter.string(from: Date())
        
        return activities
            .filter { $0.endTime > now }
            .sorted { $0.startTime < $1.startTime }
            .first
    }

    func getActivityName(icon: String) -> String {
        switch icon {
        case "sun.max.fill":       return "Wake up"
        case "drop.fill":          return "Wash up"
        case "hands.sparkles.fill": return "Prayer"
        case "fork.knife":         return "Eat"
        case "book.fill":          return "Study"
        default:                   return "Activity"
        }
    }

    func addActivity(icon: String, title: String, start: String, end: String, desc: String) {
        let newId = UUID().uuidString
        let newActivity = ScheduleActivity(
            id: newId, scheduleId: scheduleId, iconName: icon,
            startTime: start, endTime: end, description: desc,
            isCompleted: false, isValidToday: true
        )
        
        self.activities.append(newActivity)
        self.activities.sort { $0.startTime < $1.startTime }
        
        Swift.Task {
            do {
                try FirebaseManager.shared.addActivity(newActivity)
            } catch {
                self.loadActivities()
            }
        }
    }

    func updateActivity(_ activity: ScheduleActivity, start: String, end: String, desc: String) {
        var updated = activity
        updated.startTime = start
        updated.endTime = end
        updated.description = desc

        if let index = activities.firstIndex(where: { $0.id == updated.id }) {
            activities[index] = updated
            activities.sort { $0.startTime < $1.startTime }
        }

        Swift.Task {
            do {
                try FirebaseManager.shared.updateActivity(updated)
            } catch {
                self.loadActivities()
            }
        }
    }

    func deleteActivity(id: String) {
        self.activities.removeAll(where: { $0.id == id })
        
        Swift.Task {
            do {
                try await FirebaseManager.shared.deleteActivity(id: id)
            } catch {
                self.loadActivities()
            }
        }
    }


    func validateActivityTime(start: String, end: String, excludeId: String? = nil) -> (Bool, String?) {
        let startMin = timeToMinutes(start)
        let endMin = timeToMinutes(end)

        if endMin <= startMin {
            return (false, "End time tidak boleh kurang dari atau sama dengan Start time.")
        }

        for activity in activities where activity.id != excludeId {
            let eStart = timeToMinutes(activity.startTime)
            let eEnd = timeToMinutes(activity.endTime)
            if max(startMin, eStart) < min(endMin, eEnd) {
                let name = getActivityName(icon: activity.iconName)
                return (false, "Waktu bertabrakan dengan: \(name) (\(activity.startTime) - \(activity.endTime)).")
            }
        }
        return (true, nil)
    }

    private func timeToMinutes(_ time: String) -> Int {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}

