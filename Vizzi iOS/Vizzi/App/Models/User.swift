
import Foundation
import FirebaseFirestore


struct User: Identifiable, Hashable {
    var id: String
    var profilePhoto: String
    var name: String
    var username: String
    var bio : String
    var dateJoined: Date
    var authProvider: String
    var isSubscribed: Bool
    var didCompleteOnboarding : Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "objectID"
        case profilePhoto,
             name,
             username,
             bio,
             dateJoined,
             authProvider,
             isSubscribed,
             communications,
             profileStats,
             didCompleteOnboarding
    }
    
    init(from data: [String: Any]) {
        self.id = data["id"] as? String ?? ""
        self.profilePhoto = data["profilePhoto"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.username = data["username"] as? String ?? ""
        self.bio = data["bio"] as? String ?? ""
        
        if let timestamp = data["dateJoined"] as? Timestamp {
            self.dateJoined = timestamp.dateValue()
        } else {
            self.dateJoined = Date()
        }
        
        self.authProvider = data["authProvider"] as? String ?? ""
        self.isSubscribed = data["isSubscribed"] as? Bool ?? false
        self.didCompleteOnboarding = data["didCompleteOnboarding"] as? Bool ?? false
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "profilePhoto": profilePhoto,
            "name": name,
            "username": username,
            "bio" : bio,
            "dateJoined": Timestamp(date: dateJoined),
            "authProvider": authProvider,
            "isSubscribed": isSubscribed,
            "didCompleteOnboarding" : didCompleteOnboarding
        ]
    }
}


let empty_user = User(from: [
        "id": "",
        "profilePhoto": "",
        "name": "",
        "username": "",
        "bio" : "",
        "dateJoined": Date(),
        "authProvider": "",
        "isSubscribed": false,
        "didCompleteOnboarding" : true
    ]
)
