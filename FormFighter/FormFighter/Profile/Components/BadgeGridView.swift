import SwiftUI

struct BadgeItemView: View {
    let badge: Badge
    let isEarned: Bool
    let progress: BadgeProgress?
    let count: Int
    let earnedBadges: [UserBadge]
    
    init(badge: Badge, isEarned: Bool, progress: BadgeProgress?, earnedBadges: [UserBadge]) {
        self.badge = badge
        self.isEarned = isEarned
        self.progress = progress
        self.earnedBadges = earnedBadges
        self.count = earnedBadges.first { $0.badgeId == badge.id }?.count ?? (isEarned ? 1 : 0)
        
        // Debug prints
        print("🏅 Badge Init - \(badge.name)")
        print("   isEarned: \(isEarned)")
        print("   count: \(count)")
        print("   earnedBadges count: \(earnedBadges.count)")
        if let firstBadge = earnedBadges.first {
            print("   first badge ID: \(firstBadge.badgeId)")
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                if isEarned {
                    Image(systemName: badge.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.brand)
                        .onAppear {
                            print("🏅 Rendering earned badge: \(badge.name)")
                        }
                    
                    if count > 1 {
                        Text("×\(count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.brand)
                            .clipShape(Circle())
                            .offset(x: 20, y: -20)
                    }
                } else {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                        .onAppear {
                            print("❌ Rendering unearned badge: \(badge.name)")
                        }
                }
            }
            
            if let progress = progress {
                ProgressView(value: progress.percentageComplete)
                    .frame(width: 40)
            }
        }
        .frame(width: 60, height: 60)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            print("🏅 Badge appeared: \(badge.name)")
            print("   isEarned: \(isEarned)")
            print("   earnedBadges contains badge: \(earnedBadges.contains { $0.badgeId == badge.id })")
        }
    }
}

struct BadgeDetailView: View {
    let badge: Badge
    let progress: BadgeProgress?
    let isEarned: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            if isEarned {
                Image(systemName: badge.iconName)
                    .font(.system(size: 48))
                    .foregroundColor(.brand)
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
            }
            
            Text(badge.name)
                .font(.headline)
            
            if isEarned {
                Text(badge.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            if let progress = progress {
                ProgressView(value: progress.percentageComplete) {
                    Text("\(progress.currentValue)/\(progress.targetValue)")
                        .font(.caption)
                }
                .padding()
            }
        }
        .padding()
    }
}

struct BadgeGridView: View {
    let badges: [Badge]
    let earnedBadges: [UserBadge]
    let progress: [BadgeProgress]
    @State private var selectedBadge: Badge?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Badges")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(badges) { badge in
                    let isEarned = earnedBadges.contains { $0.badgeId == badge.id }
                    
                    BadgeItemView(
                        badge: badge,
                        isEarned: isEarned,
                        progress: progress.first { $0.badgeId == badge.id },
                        earnedBadges: earnedBadges
                    )
                    .onAppear {
                        print("🏅 Grid - Processing badge: \(badge.name)")
                        print("   earnedBadges count: \(earnedBadges.count)")
                        print("   isEarned: \(isEarned)")
                    }
                    .onTapGesture {
                        selectedBadge = badge
                    }
                }
            }
            .padding()
        }
        .onAppear {
            print("🏅 BadgeGridView appeared")
            print("   Total badges: \(badges.count)")
            print("   Earned badges: \(earnedBadges.count)")
            print("   Progress entries: \(progress.count)")
        }
        .sheet(item: $selectedBadge) { badge in
            let isEarned = earnedBadges.contains { $0.badgeId == badge.id }
            BadgeDetailView(
                badge: badge,
                progress: progress.first { $0.badgeId == badge.id },
                isEarned: isEarned
            )
        }
    }
}
