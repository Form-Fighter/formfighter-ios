import SwiftUI
struct NotificationPermissionView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Stay Updated")
                .font(.title2)
                .bold()
            
            Text("Enable notifications to get updates about your form analysis and feedback from your coach.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                notificationManager.requestNotificationPermission()
            } label: {
                Text("Enable Notifications")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
} 
