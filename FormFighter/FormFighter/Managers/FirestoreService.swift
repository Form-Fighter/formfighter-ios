import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

enum DatabaseError: Error {
    case noUserError
    case updateUserError
    case createUserError
    
    var localizedDescription: String {
        switch self {
        case .noUserError:
            "User does not exist in database"
        case .updateUserError:
            "Error updating user"
        case .createUserError:
            "Error creating user"
        }
    }
}

protocol DatabaseServiceProtocol {
    func fetchUser(userID: String) async throws -> User?
    func updateUser(userID: String, with model: User) async throws
    func createUser(userID: String, with model: User) async throws
    func deleteUser(userID: String)
}

// MARK: Use this class to interact with Firestore Database. Currently does CRUD operations with the User model but
// you can add similar methods up to your needs.
// If you need realtime updates, Firebase Firestore also provides functions to easily do it, listening to property changes.
// https://www.youtube.com/watch?v=a87MFlvfWvA
class FirestoreService: DatabaseServiceProtocol {
    private let db = Firestore.firestore()
    
    func fetchUser(userID: String) async throws -> User? {
        let documentReference = db.collection("users").document(userID)
        let documentSnapshot = try await documentReference.getDocument()
        
        if !documentSnapshot.exists {
            return nil
        }
        
        do {
            return try documentSnapshot.data(as: User.self)
        } catch {
            Logger.log(message: error.localizedDescription, event: .error)
            throw DatabaseError.noUserError
        }
    }
    
    func updateUser(userID: String, with model: User) throws {
        let userDocument = db.collection("users").document(userID)
        
        do {
            try userDocument.setData(from: model, merge: true)
            Logger.log(message: "User updated in Firestore: \(userID)", event: .debug)
        } catch {
            Logger.log(message: error.localizedDescription, event: .error)
            throw DatabaseError.updateUserError
        }
    }
    
    func createUser(userID: String, with model: User) async throws {
        let userDocument = db.collection("users").document(userID)
        
        do {
            try userDocument.setData(from: model)
        } catch {
            Logger.log(message: error.localizedDescription, event: .error)
            throw DatabaseError.createUserError
        }
    }
    
    func deleteUser(userID: String) {
        let userDocument = db.collection("users").document(userID)
        userDocument.delete()
        Logger.log(message: "User deleted from Firestore: \(userID)", event: .debug)
    }
}

