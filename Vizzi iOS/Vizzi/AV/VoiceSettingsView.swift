//
//  ChooseVoiceView.swift
//  AssistAid
//
//  Created by Adrian Martushev on 6/14/24.
//

import SwiftUI



// SwiftUI View
struct VoiceSettingsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var openAIVM : OpenAIViewModel
    @EnvironmentObject var appManager : AppManager
    
    func playSampleAudio() {
        let sampleText = appManager.selectedLanguage.id == "en_US" ? "Hello, I'm \(openAIVM.selectedVoice.rawValue). How can I help you today?" : "Hallo, ich bin \(openAIVM.selectedVoice.rawValue). Wie kann ich Ihnen heute helfen?"
        Task {
            await openAIVM.synthesizeResponse(from: sampleText)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.playSampleAudio()
                }, label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.white)
                })
                Spacer()
                
                Text("Settings")
                    .font(.system(size: 14, weight : .semibold))
                    .padding()
                Spacer()
                
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                })
            }
            .padding()
            
            ScrollView(showsIndicators : false) {
                SpeechCirclePatternView(width : 50.0, height: 50.0, isAudioPlaying: $openAIVM.isAudioPlaying)
                
                Spacer()
                
                HStack {
                    Text(NSLocalizedString("choose_language", comment: ""))
                        .font(.title2)
                    Spacer()
                    
                }
                .padding(.horizontal)
                
                ForEach(languageOptions, id: \.id) { language in

                    Button(action: {
                        appManager.setSelectedLanguage(language)

                    }, label: {
                        HStack {
                            Text(language.title)
                            Spacer()
                            if language == appManager.selectedLanguage {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding()
                        .background(.gray.opacity(0.2))
                        .cornerRadius(20)
                        .foregroundStyle(.white)

                    })
                }
                .padding(.horizontal)
                            
                HStack {
                    Text(NSLocalizedString("choose_voice", comment: ""))
                        .font(.title2)
                    Spacer()
                    
                }
                .padding(.horizontal)
                
                ForEach(openAIVM.voices, id: \.self) { voice in
                    Button(action: {
                        openAIVM.selectedVoice = voice

                    }, label: {
                        HStack {
                            Text(voice.rawValue.capitalized)
                            Spacer()
                            if voice == openAIVM.selectedVoice {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                        .foregroundStyle(.white)
                    })
                }
                .padding(.horizontal)
                

            }
        }
    }
}


struct SpeechCirclePatternView: View {
    var width: CGFloat
    var height: CGFloat
    @Binding var isAudioPlaying: Bool
    
    @State private var heights: [CGFloat] = [1.0, 1.0, 1.0, 1.0]
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: width / 2)
                    .fill(Color.white)
                    .frame(width: width, height: height * heights[index])
                    .onChange(of: isAudioPlaying) { _, playing in
                        if playing {
                            withAnimation(Animation.easeInOut(duration: 0.5 + Double(index) * 0.1).repeatForever(autoreverses: true)) {
                                heights[index] = 1.0 + CGFloat(index) * 0.3
                            }
                        } else {
                            withAnimation {
                                heights[index] = 1.0
                            }
                        }
                    }
            }
        }
        .frame(height: height * 1.8)
        .onAppear {
            for index in 0..<4 {
                heights[index] = 1.0
            }
        }
    }
}



struct CirclePatternView: View {
    var width: CGFloat
    var height: CGFloat


    @State private var animateFirstBar = false
    @State private var animateSecondBar = false
    @State private var animateThirdBar = false
    @State private var animateFourthBar = false

    var body: some View {
        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: width / 2)
                .fill(Color.white)
                .frame(width: width, height: height * (animateFirstBar ? 1.5 : 1.0))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        animateFirstBar.toggle()
                    }
                }
            
            RoundedRectangle(cornerRadius: width / 2)
                .fill(Color.white)
                .frame(width: width, height: height * (animateSecondBar ? 1.2 : 0.8))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        animateSecondBar.toggle()
                    }
                }
            
            RoundedRectangle(cornerRadius: width / 2)
                .fill(Color.white)
                .frame(width: width, height: height * (animateThirdBar ? 1.8 : 1.3))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        animateThirdBar.toggle()
                    }
                }
            
            RoundedRectangle(cornerRadius: width / 2)
                .fill(Color.white)
                .frame(width: width, height: height * (animateFourthBar ? 1.1 : 0.9))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        animateFourthBar.toggle()
                    }
                }
        }
        .frame(height : height * 1.8)
    }
}

#Preview {
    VoiceSettingsView()
        .environmentObject(OpenAIViewModel())
}
