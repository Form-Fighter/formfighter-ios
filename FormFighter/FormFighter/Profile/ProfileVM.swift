//
//  ProfileVM.swift
//  FormFighter
//
//  Created by Julian Parker on 10/4/24.
//


import Foundation
import Firebase
import FirebaseFirestore
import os.log
import Combine

class ProfileVM: ObservableObject {
    @Published var isLoading = false
    @Published var feedbacks: [FeedbackListItem] = []
    @Published var badges: [Badge] = []
    @Published var earnedBadges: [UserBadge] = []
    @Published var badgeProgress: [BadgeProgress] = []
    
    private let feedbackManager: FeedbackManager
    private let badgeService = BadgeService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(feedbackManager: FeedbackManager = .shared) {
        self.feedbackManager = feedbackManager
        
        // Start badge listener if user is authenticated
        if let userId = Auth.auth().currentUser?.uid {
            BadgeService.shared.startListening(userId: userId)
        }
        
        // Subscribe to badge service updates
        badgeService.$userBadges
            .assign(to: &$earnedBadges)
        
        badgeService.$badgeProgress
            .assign(to: &$badgeProgress)
            
        // Observe changes to FeedbackManager's properties
        feedbackManager.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
            
        feedbackManager.$feedbacks
            .assign(to: \.feedbacks, on: self)
            .store(in: &cancellables)
        
        // Load badges
        loadBadges()
    }
    
    private func loadBadges() {
        badges = [
            Badge(id: "first_jab", name: "First Jab", description: "Complete your first training session", type: .instant, iconName: "star.fill", targetValue: nil, category: .milestone),
            Badge(id: "perfect_score", name: "Perfect Form", description: "Score 9.5 or higher", type: .instant, iconName: "trophy.fill", targetValue: nil, category: .performance),
            Badge(id: "extension_master", name: "Extension Master", description: "Score 9.0+ on extension", type: .instant, iconName: "hand.raised.fill", targetValue: nil, category: .performance),
            Badge(id: "early_bird", name: "Early Bird", description: "Train before 6 AM", type: .instant, iconName: "sunrise.fill", targetValue: nil, category: .fun),
            Badge(id: "night_owl", name: "Night Owl", description: "Train after 10 PM", type: .instant, iconName: "moon.stars.fill", targetValue: nil, category: .fun),
            Badge(id: "three_day_streak", name: "Three Day Streak", description: "Train for 3 days in a row", type: .progress, iconName: "flame.fill", targetValue: 3, category: .streak),
            Badge(id: "weekly_warrior", name: "Weekly Warrior", description: "Train for 7 days in a row", type: .progress, iconName: "flame.fill", targetValue: 7, category: .streak),
            Badge(id: "unstoppable", name: "Unstoppable", description: "Train for 14 days in a row", type: .progress, iconName: "flame.fill", targetValue: 14, category: .streak),
            Badge(id: "monthly_master", name: "Monthly Master", description: "Train for 30 days in a row", type: .progress, iconName: "flame.fill", targetValue: 30, category: .streak),
            Badge(id: "jab_rookie", name: "Jab Rookie", description: "Complete 100 jabs", type: .cumulative, iconName: "figure.boxing", targetValue: 100, category: .volume),
            Badge(id: "jab_veteran", name: "Jab Veteran", description: "Complete 500 jabs", type: .cumulative, iconName: "figure.boxing", targetValue: 500, category: .volume),
            Badge(id: "jab_master", name: "Jab Master", description: "Complete 1000 jabs", type: .cumulative, iconName: "figure.boxing", targetValue: 1000, category: .volume)
        ]
    }
    
    func getBadge(id: String) -> Badge? {
        badges.first { $0.id == id }
    }
}

// Badge Model

