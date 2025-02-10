
import SwiftUI
import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseStorage



class CurrentUserViewModel : NSObject, ObservableObject {
    let delegate = UIApplication.shared.delegate as! AppDelegate

    @Published var user : User = empty_user
    
    //Handles real-time authentication changes to conditionally display login/home views
    var didChange = PassthroughSubject<CurrentUserViewModel, Never>()
    
    @Published var currentUserID: String = "" {
        didSet {
            didChange.send(self)
        }
    }
    
    var handle: AuthStateDidChangeListenerHandle?
    var coreUserChangesListener: ListenerRegistration?

    func listen () {
        handle = Auth.auth().addStateDidChangeListener { [self] (auth, user) in
            if let user = user {
                
                print("User Authenticated: \(user.uid)")
                self.currentUserID = user.uid
                self.getUserInfo(userID: user.uid)
                

            } else {
                print("No user available, loading initial view")
                self.currentUserID = ""
            }
        }
    }
    
    //Fetch initial data once, add listeners for appropriate conditions
    func getUserInfo(userID: String) {
        let userInfo = database.collection("users").document(userID)
        
        userInfo.getDocument { documentSnapshot, error in
            guard documentSnapshot != nil else {
                print("Error fetching document: \(error!)")
                return
            }

            self.listenForCoreUserChanges(userID: self.currentUserID)
        }
    }
    
    func listenForCoreUserChanges(userID: String) {
        coreUserChangesListener = database.collection("users").document(userID).addSnapshotListener { snapshot, error in
            guard let document = snapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            
            guard let userData = document.data() else {
                print("User is authenticated but no user document exists.")
                return
            }
            
            let user = User(from: userData)
            self.user = user
        }
    }
    
    func fetchOnboardingStatus(completion: @escaping (Bool) -> Void) {
        database.collection("users").document(self.currentUserID).getDocument { document, error in
            guard let document = document, document.exists, let data = document.data() else {
                completion(false)
                return
            }

            let didCompleteOnboarding = data["didCompleteOnboarding"] as? Bool ?? false
            self.user.didCompleteOnboarding = didCompleteOnboarding
            completion(didCompleteOnboarding)
        }
    }

    
    //MARK: User Updates
    func updateUser(data: [String: Any]) {
        
        if self.currentUserID != "" {
            let userInfo = database.collection("users").document(self.currentUserID)
            userInfo.updateData(data) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("User data successfully updated: \(data)")
                }
            }
        } else {
            print("Attempting to update non existent user with data : \(data)")
        }
    }
    
    func updateUserWithCompletion(data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        
        let userInfo = database.collection("users").document(self.currentUserID)
        userInfo.updateData(data) { err in
            if let err = err {
                print("Error updating document: \(err)")
                completion(.failure(err))
            } else {
                print("User data successfully updated : \(data)")
                completion(.success(()))
            }
        }
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        let imageData = image.jpegData(compressionQuality: 0.4)
        let storageRef = Storage.storage().reference().child("profilePhotos/\(self.currentUserID).jpg")

        storageRef.putData(imageData!, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
    }
    
    func updateUserProfilePhotoURL(_ url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()

        db.collection("users").document(self.currentUserID).updateData(["profilePhoto": url.absoluteString]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Successfully updated profile photo")
                completion(.success(()))
            }
        }
    }
    
    //MARK: Termination Steps
    func signOut(appManager : AppManager) {
        do {
            coreUserChangesListener?.remove()
            coreUserChangesListener = nil
            
            try Auth.auth().signOut()
            print("Successfully signed out user")
            resetCurrentUserVM()
            appManager.navigationPath = [.onboarding]
            
        } catch {
            print("Error signing out user")
        }
    }
    
    func resetCurrentUserVM() {
        print("Resetting CurrentUserViewModel")
            
        currentUserID = ""
        user = empty_user
    }
}
