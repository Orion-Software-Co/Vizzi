
import SwiftUI

struct MotherView: View {
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var currentUserVM: CurrentUserViewModel

    var body: some View {
        ZStack {
            VStack(spacing : 0) {
                NavigationStack(path: $appManager.navigationPath) {
                    EmptyView()
                        .navigationDestination(for: NavigationState.self) { index in
                            switch index {

                            case .onboarding :
                                OnboardingView()
                                    .toolbar(.hidden)
                                
                            case .app :
                                ZStack {
                                    Group {
                                        switch appManager.tabShowing {
                                        case .Home:
                                            HomeView()
                                                .toolbar(.hidden)
                                            
                                        case .Navigation :
                                            MapNavigationView()
                                                .toolbar(.hidden)
                                            
                                        case .Camera :
                                            CameraView()
                                                .toolbar(.hidden)
                                            
                                        case .Reality :
                                            RealityView()
                                                .toolbar(.hidden)

                                        case .AudioSpaces :
                                            AudioSpacesView()
                                                .toolbar(.hidden)
                                            
                                        case .Settings :
                                            SettingsView()
                                                .toolbar(.hidden)
                                        }
                                    }

                                    VStack {
                                        Spacer()
                                        
                                        TabsLayoutView(selectedTab: $appManager.tabShowing)
                                    }
                                    .padding(.bottom, 20)
                                    
                                    VStack {
                                        Spacer()
                                        
                                        HStack {
                                            Spacer()
                                            AVInputView()
                                        }
                                        .padding(.trailing, 20)
                                    }
                                    .padding(.bottom, 20)

                                }
                                .background(.ultraThinMaterial)
                            }
                        }
                }
            }
            
            if appManager.showSplashScreen {
                SplashScreen()
            }
        }
        .background(.ultraThinMaterial)
        .animation(.default, value: keyboardResponder.isKeyboardVisible)
        .animation(.default, value: appManager.showSplashScreen)
        .onAppear {
            handleAppInitialization()
        }
    }
    
    private func handleAppInitialization() {
        currentUserVM.listen()
        appManager.showSplash()
    }
}



fileprivate struct TabsLayoutView: View {
    @EnvironmentObject var appManager: AppManager
    @Binding var selectedTab: Tab
    @Namespace var namespace
    
    var body: some View {
        HStack {
            Spacer()
            TabButton(tab: .Home, selectedTab: $selectedTab, namespace: namespace)
            Spacer()
            TabButton(tab: .Navigation, selectedTab: $selectedTab, namespace: namespace)
            Spacer()
            TabButton(tab: .Camera, selectedTab: $selectedTab, namespace: namespace)
            Spacer()
            TabButton(tab: .Reality, selectedTab: $selectedTab, namespace: namespace)
            Spacer()
            TabButton(tab: .AudioSpaces, selectedTab: $selectedTab, namespace: namespace)
            Spacer()
            TabButton(tab: .Settings, selectedTab: $selectedTab, namespace: namespace)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .frame(maxWidth : 500)
        .cornerRadius(100)
        .overlay {
            RoundedRectangle(cornerRadius: 100)
                .stroke(.silk.opacity(0.2), lineWidth: 0.5)
        }
        .shadow(color : .black.opacity(0.1), radius: 5, x: 0, y: 10)
        .padding(.horizontal)
    }
    
    private struct TabButton: View {
        let tab: Tab
        @Binding var selectedTab: Tab
        var namespace: Namespace.ID
        @EnvironmentObject var appManager: AppManager

        var body: some View {
            Button {
                generateHapticFeedback(style: .soft)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.9, blendDuration: 0.6)) {
                    selectedTab = tab
                    appManager.navigationPath = [.app]
                }
            } label: {
                VStack (spacing : 0) {
                    Image(systemName: tab.icon )
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.4) )
                        .font(.system(size: 30, weight: selectedTab == tab ? .semibold : .light, design: .rounded))
                        .scaleEffect(isSelected ? 1 : 0.9)
                        .animation(isSelected ? .spring(response: 0.5, dampingFraction: 0.3, blendDuration: 1) : .spring(), value: selectedTab)
                    
                }
                .frame(width : 70, height : 70)
            }
            .frame(width : 70, height : 70)
        }
        
        private var isSelected: Bool {
            selectedTab == tab
        }
    }
}


#Preview {
    MotherView()
        .environmentObject(KeyboardResponder())
        .environmentObject(AppManager())
        .environmentObject(CurrentUserViewModel())
        .environmentObject(OpenAIViewModel())

}
