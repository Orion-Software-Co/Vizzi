import Foundation
import UIKit
import SwiftUI
import Firebase


enum Tab: Int, Identifiable, CaseIterable, Comparable {
    static func < (lhs: Tab, rhs: Tab) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case Home, Navigation, Camera, Reality, AudioSpaces, Settings
    
    internal var id: Int { rawValue }
    
    var icon: String {
        switch self {
        case .Home:
            return "house.fill"
        case .Navigation:
            return "map.fill"
        case .Camera:
            return "camera.metering.center.weighted.average"
        case .Reality:
            return "camera.viewfinder"
        case .AudioSpaces:
            return "waveform"
        case .Settings:
            return "gear"
        }
    }
}

enum NavigationState : Hashable {
    case onboarding
    case app
}

//Public initialization of Firebase Firestore
let database = Firestore.firestore()

struct Language : Identifiable, Equatable, Codable {
    var id : String
    var code : String
    var title : String
}

var languageOptions : [Language] = [
    Language(id: "en-US", code: "en-US", title: "English"),
    Language(id: "de_DE", code: "de_DE", title: "German"),
    Language(id: "fr_FR", code: "fr_FR", title: "French"),
    Language(id: "es_MX", code: "es_MX", title: "Spanish"),
    Language(id: "it_IT", code: "it_IT", title: "Italian"),
]

class AppManager : ObservableObject {
    static let shared = AppManager()
    
    init() {
        self.selectedLanguage = self.loadSelectedLanguage() ?? languageOptions.first(where: { $0.code == "en-US" }) ?? languageOptions.first!

        if self.didCompleteOnboarding {
            navigationPath = [.app]
        } else {
            navigationPath = [.app]
        }
    }

    @Published var navigationPath: [NavigationState] = [.onboarding]
    @Published var tabShowing: Tab = Tab.Home
    @Published var showSplashScreen = true
    @Published var selectedLanguage: Language = Language(id: "en-US", code: "en-US", title: "English")
    @Published var didCompleteOnboarding = false
    @Published var showCamera: Bool = false

    
    // MARK: - Language Settings
    func setSelectedLanguage(_ language: Language) {
        selectedLanguage = language
        // Save the language's ID or code in UserDefaults
        UserDefaults.standard.set(language.id, forKey: "selectedLanguage")

    }

    func loadSelectedLanguage() -> Language? {
        // Retrieve the saved language ID from UserDefaults
        if let savedLanguageID = UserDefaults.standard.string(forKey: "selectedLanguage") {
            // Find the corresponding language in the language options
            return languageOptions.first(where: { $0.id == savedLanguageID })
        }
        return nil
    }
    
    
    // MARK: - Onboarding Settings
    func setDidCompleteOnboarding(_ completed: Bool) {
        didCompleteOnboarding = completed
        UserDefaults.standard.set(completed, forKey: "didCompleteOnboarding")
    }
    
    func getDidCompleteOnboarding() -> Bool {
        return didCompleteOnboarding
    }
    
    func navigateBack() {
        if navigationPath.count > 1 {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath = [.app]
    }
    
    func popToHome() {
        navigationPath = [.app]
    }
    
    func showSplash() {
        self.showSplashScreen = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.showSplashScreen = false
            }
        }
    }
    
    func showSplashAndNavigateToApp() {
        showSplash()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Slight delay to mask navigation
            self.navigationPath = [.app]
        }
    }
    
    func showSplashAndNavigateTo(path : NavigationState) {
        showSplash()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Slight delay to mask navigation
            self.navigationPath = [path]
        }
    }
}
