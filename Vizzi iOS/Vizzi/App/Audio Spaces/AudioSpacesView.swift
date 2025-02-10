//
//  AudioSpacesView.swift
//  Vizzi
//
//  Created by Adrian Martushev on 1/27/25.
//

import SwiftUI

struct AudioSpace : Identifiable {
    var id : UUID = UUID()
    var image: String
    var title: String
    var description : String
}


struct AudioSpacesView: View {
    @EnvironmentObject var spacesVM : AudioSpacesViewModel
    
    let audioSpaces : [AudioSpace] = [
        AudioSpace(image : "mountkilimanjaro", title: "Mount Kilimanjaro", description: """
        This image showcases a breathtaking view of a natural landscape during what appears to be either sunrise or sunset. The scene is dominated by Mount Kilimanjaro, a majestic and iconic mountain, which rises above the horizon, partially surrounded by a layer of clouds. The mountain's peak is visible, slightly snow-capped, contrasting with its darker slopes.
                   
        In the foreground, a savanna landscape stretches out with sparse, flat-topped acacia trees scattered across the terrain, evoking a quintessential African scene. The lighting creates a golden glow, bathing the clouds, mountain, and savanna in warm hues of orange, yellow, and gold, while the shadows add depth to the scenery. This creates a tranquil and awe-inspiring ambiance, highlighting the natural beauty of the region.
        """),
        AudioSpace(image : "niagarafalls", title: "Niagara Falls", description: """
        This image captures the grandeur of Niagara Falls, a famous natural landmark straddling the border between the United States and Canada. The view showcases two of the primary waterfalls: the American Falls on the left and the Horseshoe Falls on the right, separated by lush green vegetation and a rocky river island. Both waterfalls are surrounded by verdant forests and cascading whitewater, creating a vibrant contrast against the turquoise river below. A boat, likely part of a tour, appears near the base of the falls, dwarfed by the towering cascades and the mist rising from the water. In the foreground, there is a park area with people gathered, trees, and observation platforms. The scene is bright and sunny, with a sky dotted by fluffy white clouds, enhancing the vibrant and dynamic beauty of this iconic destination.
        """),
        AudioSpace(image : "mountkilimanjaro", title: "Mount Kilimanjaro", description: ""),
        AudioSpace(image : "mountkilimanjaro", title: "Mount Kilimanjaro", description: ""),
        AudioSpace(image : "mountkilimanjaro", title: "Mount Kilimanjaro", description: ""),
        AudioSpace(image : "mountkilimanjaro", title: "Mount Kilimanjaro", description: "")
    ]
    
    @State var showAudioPlaceDetails : Bool = false
    
    var body: some View {
        
        VStack {
            HStack {
                Text("Audio Places")
                    .font(.system(size: 29, weight : .bold))
                Spacer()
            }
            .padding(.bottom, 24)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 40) {
                    
                    ForEach( audioSpaces, id : \.id ) { space in
                        Button {
                            showAudioPlaceDetails = true
                            spacesVM.selectedAudioSpace = space
                        } label : {
                            AudioSpacePreview(audioSpace: space)
                        }
                        .cornerRadius(8)

                    }
                }
            }
            
            Spacer()
            
        }
        .padding(24)
        .fullScreenCover(isPresented: $showAudioPlaceDetails) {
            AudioSpaceDetailsView()
        }
    }
}

struct AudioSpacePreview : View {
    var audioSpace : AudioSpace
    
    var width = UIScreen.main.bounds.width / 4
    
    var body: some View {
        VStack(alignment : .leading) {
            Image(audioSpace.image)
                .resizable()
                .scaledToFill()
                .frame(width : width, height : width)
                .clipped()
                .cornerRadius(8, corners: [.topLeft, .topRight])
            
            VStack(alignment : .leading) {
                Text(audioSpace.title)
                    .font(.system(size: 24, weight : .semibold))
                
                Text("January 5th, 2024")
                    .font(.system(size: 16))

            }
            .padding(8)
            .foregroundStyle(.white)
        }
        .padding(8)
        .background(.regularMaterial)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}


struct AudioSpaceDetailsView : View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var AIVM : OpenAIViewModel
    @EnvironmentObject var spacesVM : AudioSpacesViewModel

    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button {
                    dismiss()
                } label : {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                        .frame(width : 50, height : 50)
                        .background(.regularMaterial)
                        .cornerRadius(100)
                        .overlay {
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(.silk.opacity(0.2), lineWidth: 0.5)
                        }
                }
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "chevron.left")
                Spacer()
                Image(systemName: "chevron.right")
            }
            
            Spacer()
            
            HStack {
                Button {
                    
                } label: {
                    Text("Play Audio")
                        .foregroundStyle(.white)
                        .font(.system(size: 24, weight: .medium))
                        .frame(width : 180, height : 80)
                        .background(.regularMaterial)
                        .cornerRadius(100)
                        .overlay {
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(.silk.opacity(0.2), lineWidth: 0.5)
                        }
                }
                .frame(width : 200, height : 100)
                .cornerRadius(100)
                .shadow(color : .black.opacity(0.1), radius: 5, x: 0, y: 10)
                
                Button {
                    Task {
                        await AIVM.synthesizeResponse(from: spacesVM.selectedAudioSpace.description)
                    }
                } label: {
                    Text("Describe")
                        .foregroundStyle(.white)
                        .font(.system(size: 24, weight: .medium))
                        .frame(width : 180, height : 80)
                        .background(.regularMaterial)
                        .cornerRadius(100)
                        .overlay {
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(.silk.opacity(0.2), lineWidth: 0.5)
                        }
                }
                .frame(width : 200, height : 100)
                .cornerRadius(100)
                .shadow(color : .black.opacity(0.1), radius: 5, x: 0, y: 10)
            }
        }
        .padding(24)
        .background {
            Image(spacesVM.selectedAudioSpace.image)
                .resizable()
                .scaledToFill()
                .clipped()
        }
    }
}



#Preview {
    VStack {
        AudioSpacesView()

    }
    .background(.charcoal)
    .background(.ultraThickMaterial)
    .environmentObject(OpenAIViewModel())
    .environmentObject(AudioSpacesViewModel())

}
