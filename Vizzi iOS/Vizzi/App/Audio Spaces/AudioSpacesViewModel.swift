//
//  AudioSpacesViewModel.swift
//  Vizzi
//
//  Created by Adrian Martushev on 1/27/25.
//

import Foundation


class AudioSpacesViewModel: ObservableObject {
    
    @Published var selectedAudioSpace : AudioSpace = AudioSpace(image : "mountkilimanjaro", title: "Mount Kilimanjaro", description: """
        This image showcases a breathtaking view of a natural landscape during what appears to be either sunrise or sunset. The scene is dominated by Mount Kilimanjaro, a majestic and iconic mountain, which rises above the horizon, partially surrounded by a layer of clouds. The mountain's peak is visible, slightly snow-capped, contrasting with its darker slopes.
                   
        In the foreground, a savanna landscape stretches out with sparse, flat-topped acacia trees scattered across the terrain, evoking a quintessential African scene. The lighting creates a golden glow, bathing the clouds, mountain, and savanna in warm hues of orange, yellow, and gold, while the shadows add depth to the scenery. This creates a tranquil and awe-inspiring ambiance, highlighting the natural beauty of the region.
        """)
    
    @Published var audioSpaces : [AudioSpace] = []
}
