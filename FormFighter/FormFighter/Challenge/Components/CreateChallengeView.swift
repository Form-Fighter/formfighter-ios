import SwiftUI

struct CreateChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChallengeViewModel
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    @State private var error: Error?
    @State private var showError = false
    
    private let suggestions = [
        "Winner gets bragging rights 👑",
        "Loser buys coffee ☕️",
        "Prove who's the best boxer 🥊",
        "Challenge your gym buddies 💪"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Challenge Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Challenge Details")
                } footer: {
                    Text("Challenge will last for 2 hours once created")
                }
                
                Section("Suggested Stakes") {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            description = suggestion
                        } label: {
                            Text(suggestion)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await createChallenge()
                        }
                    } label: {
                        HStack {
                            Text("Create Challenge")
                            if isCreating {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(name.isEmpty || description.isEmpty || isCreating)
                }
            }
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError, presenting: error) { _ in
                Button("OK") {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    
    private func createChallenge() async {
        await MainActor.run {
            isCreating = true
        }
        defer { 
            Task { @MainActor in
                isCreating = false
            }
        }
        
        do {
            try await viewModel.createChallenge(name: name, description: description)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                self.error = error
                showError = true
            }
        }
    }
} 
