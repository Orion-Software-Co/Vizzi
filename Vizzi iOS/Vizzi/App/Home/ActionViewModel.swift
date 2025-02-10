//
//  ActionViewModel.swift
//  Vizzi
//
//  Created by Adrian Martushev on 1/27/25.
//

import Foundation



struct Action {
    var category: ActionCategory
    var subtext: String
}

enum ActionCategory {
    case navigation, audioSpace
}

class ActionViewModel: ObservableObject {
    @Published var actions: [Action] = [
        Action(category: .navigation, subtext: "Market of Choice Eugene"),
        Action(category: .navigation, subtext: "5th Street Public Market"),
        Action(category: .navigation, subtext: "Amazon Park Eugene"),
        Action(category: .audioSpace, subtext: "Oregon Coast January 5th"),
        Action(category: .audioSpace, subtext: "Spencers Butte Trip")
    ]
    
    func performAction(action : Action, appManager : AppManager, mapVM : MapViewModel) {
        switch action.category {
        case .navigation:
            performNavigation(action: action, appManager: appManager, mapVM: mapVM)
        case .audioSpace:
            openAudioSpace(appManager: appManager)
        }
    }
    
    func performNavigation(action : Action, appManager : AppManager, mapVM : MapViewModel) {
        DispatchQueue.main.async {
            appManager.tabShowing = .Navigation
        }
        
        mapVM.performSearch(query: action.subtext) { results, error in
            if let firstResult = results?.first {
                mapVM.getDirections(to: firstResult)
            }
        }
    }
    
    func openAudioSpace(appManager : AppManager) {
        appManager.tabShowing = .AudioSpaces
    }
}
