import SwiftUI

struct TestCrashlyticsView: View {
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading) {
                Text("This is a debug view to force a crash and send a report to Crashlytics in order to configure it or test crashes")
                    .font(.special(.title2, weight: .bold))
                    .padding(.bottom)
                Text("1. RUN the app from Xcode in your test device or Simulator")
                Text("2. STOP the run")
                Text("3. Open the app from the device or Simulator, NOT from Xcode, as the Xcode debugger prevent sending crashes to Crashlytics")
                Text("4. Hit the button bellow to force a crash and then comment or delete this view from the project")
            }
            
            RoundedButton(title: "Crash", color: .ruby) {
              fatalError("Crash was triggered")
            }

        }
        .padding()
    }
}

#Preview {
    TestCrashlyticsView()
}
