import SwiftUI

struct RealityView: View {

    var body: some View {
        ARSCNViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    RealityView()
}
