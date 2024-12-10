import Foundation

enum ChallengeError: Error, LocalizedError {
    case invalidChallenge
    case alreadyInChallenge
    case challengeEnded
    case participantUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidChallenge:
            return "Challenge not found or invalid"
        case .alreadyInChallenge:
            return "You are already in an active challenge"
        case .challengeEnded:
            return "This challenge has ended"
        case .participantUpdateFailed:
            return "Failed to update participant data"
        }
    }
} 