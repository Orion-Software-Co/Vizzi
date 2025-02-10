//
//  AVInputView.swift
//  Vizzi
//
//  Created by Adrian Martushev on 1/26/25.
//

import SwiftUI
import AVFoundation
import Speech


struct AVInputView: View {
    @EnvironmentObject var openAIVM : OpenAIViewModel
    @EnvironmentObject var appManager : AppManager
    @EnvironmentObject var mapVM : MapViewModel

    @State private var audioEngine = AVAudioEngine()
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State var isRecording = false
    
    func checkPermissionsAndStartRecording() {
        requestAuthorizationAndStartRecording()
    }
    
    var body: some View {
        ZStack(alignment : .bottomTrailing) {
            
            VStack(alignment : .trailing) {
                HStack {
                    if !openAIVM.query.isEmpty {
                        Text(openAIVM.query)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.leading)
                            .padding()
                            .padding(.horizontal, 8)
                            .background(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 35)
                                    .stroke(.silk.opacity(0.2), lineWidth: 0.5)
                            }
                            .shadow(color : .black.opacity(0.1), radius: 5, x: 0, y: 10)
                            .cornerRadius(35, corners: [.bottomLeft, .topLeft, .topRight])
                            .frame(maxWidth : 450)
                            .padding(.bottom, 20)
                    }
                }
                
                Button(action: {
                    if openAIVM.isResponding {
                        openAIVM.stopAudio()
                    } else if isRecording {
                        endRecording(isFinal: true)
                        isRecording = false
                        print("Recording stopped")
                    } else {
                        checkPermissionsAndStartRecording()
                    }
                }) {
                    ZStack {
                        Image(systemName: openAIVM.isResponding ? "stop.fill" : (isRecording ? "xmark" : "mic.fill"))
                            .foregroundColor(.white)
                            .font(.system(size: 28))
                    }
                    .frame(width : 100, height : 100)
                    .background(.ultraThinMaterial)
                    .cornerRadius(100)
                    .overlay {
                        RoundedRectangle(cornerRadius: 100)
                            .stroke(.silk.opacity(0.2), lineWidth: 0.5)
                    }
                }
                .frame(width : 100, height : 100)
                .cornerRadius(100)
                .shadow(color : .black.opacity(0.1), radius: 5, x: 0, y: 10)


            }

        }
    }
}



extension AVInputView {
    func requestAuthorizationAndStartRecording() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                try? self.startRecording()
                            }
                        }
                    }
                default:
                    print("Speech recognition authorization was not granted.")
                }
            }
        }
    }
    
    func startRecording() throws {
        self.isRecording = true
        
        let selectedLocale = Locale(identifier: appManager.selectedLanguage.code)
        speechRecognizer = SFSpeechRecognizer(locale: selectedLocale)

        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil

        // Configure audio session for the recording.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create a new recognition request.
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        recognitionRequest.shouldReportPartialResults = true

        // Setup a recognition task for the speech recognizer.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [self] result, error in
            if let result = result, !result.bestTranscription.formattedString.isEmpty {
                // Only update if there's a non-empty transcription
                openAIVM.query = result.bestTranscription.formattedString
                print(openAIVM.query)
                
                if error != nil || result.isFinal  {
                    self.endRecording(isFinal: result.isFinal )
                }
            }
        }

        // Configure the microphone input.
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }

        // Start the audio engine.
        audioEngine.prepare()
        try audioEngine.start()
    }

    func endRecording(isFinal: Bool) {
        isRecording = false
        audioEngine.stop()
        
        let inputNode = audioEngine.inputNode
        if inputNode.outputFormat(forBus: 0).channelCount > 0 {
            inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        if isFinal {
            Task {
                await openAIVM.classifyQuery(appManager: appManager, mapVM : mapVM)
            }
        }
    }
}


#Preview {
    AVInputView()
        .environmentObject(OpenAIViewModel())
}
