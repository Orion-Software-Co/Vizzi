
import SwiftUI

struct CircleIconLabel : View {
    var icon : String
    var isSystemIcon : Bool = true
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width : 36, height : 36)
                .foregroundStyle(.white)
            
            if isSystemIcon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.black)

            } else {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width : 20, height: 20)
            }
        }
    }
}

#Preview {
    CircleIconLabel(icon: "xmark")
}
