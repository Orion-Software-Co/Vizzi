import SwiftUI

struct SplashScreen: View {
    var body: some View {
        
        VStack {
            
            Spacer()
            
            HStack {
                Spacer()
                
                
                ZStack {
                    Image(.appLogo)
                        .resizable()
                        .scaledToFit()
                }
                .frame(width : 120, height : 120)
                .background(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.01), lineWidth : 1)
                }
                .cornerRadius(25)
                .shadow(color : .gray.opacity(0.1), radius: 0.5, x : 0, y : 1)
                .shadow(color : .white.opacity(0.4), radius: 0.5, x : 0, y : -1)
                
                
                Spacer()
            }
            
            Spacer()

        }
        .background(.regularMaterial)
    }
}

#Preview {
    SplashScreen()
}
