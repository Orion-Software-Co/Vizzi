//
//  HomeView.swift
//  Vizzi
//
//  Created by Adrian Martushev on 1/26/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var mapVM: MapViewModel

    @StateObject var actionVM = ActionViewModel()
    
    var body: some View {
        VStack(alignment : .leading) {
            
            HStack {
                Text("Quick Actions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "plus")
            }
            .padding(.top, 20)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 3), spacing: 30) {
                ForEach(actionVM.actions.indices, id: \.self) { index in
                    let action = actionVM.actions[index]
                    
                    Button {
                        actionVM.performAction(action: action, appManager: appManager, mapVM: mapVM)
                    } label : {
                        ActionCard(
                            icon: fetchIcon(for: action.category),
                            iconColor: fetchIconColor(for: action.category),
                            actionText: fetchActionText(for: action.category),
                            actionSubtext: action.subtext
                        )
                    }
                }
            }
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth : .infinity)
    }
    
    // Helper functions to fetch icon, color, and text
    func fetchIcon(for category: ActionCategory) -> String {
        switch category {
        case .navigation:
            return "location.fill"
        case .audioSpace:
            return "mic.fill"
        }
    }
    
    func fetchIconColor(for category: ActionCategory) -> Color {
        switch category {
        case .navigation:
            return .blue
        case .audioSpace:
            return .purple
        }
    }
    
    func fetchActionText(for category: ActionCategory) -> String {
        switch category {
        case .navigation:
            return "Get directions to..."
        case .audioSpace:
            return "Open Audio Space..."
        }
    }
}

struct ActionCard: View {
    var icon: String
    var iconColor: Color
    var actionText: String
    var actionSubtext: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            Text(actionText)
                .font(.system(size: 24, weight : .medium))
                .foregroundColor(.white)
            
            Text(actionSubtext)
                .font(.system(size: 24))
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}



#Preview {
    
    VStack {
        HomeView()

    }
    .background(.charcoal)
    .background(.ultraThickMaterial)
}
