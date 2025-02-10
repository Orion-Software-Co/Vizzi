//
//  SearchField.swift
//  Vizzi
//
//  Created by Adrian Martushev on 1/26/25.
//

import SwiftUI
import AVKit
import Speech
import Lottie

struct SearchFieldView: View {
    @State var text : String = ""
    
    var body: some View {
        VStack {
            Spacer()
            SearchField(text: $text, placeholder: "Search")
            Spacer()
            
        }
        .background(.regularMaterial)
    }
}


#if canImport(Combine) && canImport(SwiftUI) && (arch(arm64) || arch(x86_64)) && !os(tvOS)
  import Combine
  import SwiftUI

  /// A specialized view for receiving search query text from the user.
  @available(iOS 13.0, OSX 11.0, tvOS 13.0, watchOS 6.0, *)
  public struct SearchField: View {

    /// Search query text
    @Binding public var text: String

    /// Whether the search bar is in the editing state
    @State var isEditing: Bool = false

    var placeholder: String
    private var onSubmit: () -> Void

      public init(text: Binding<String>,
                placeholder: String,
                onSubmit: @escaping () -> Void = {}) {
          
          _text = text
          self.placeholder = placeholder
          self.onSubmit = onSubmit
    }
      
    @State private var audioEngine = AVAudioEngine()
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State var isRecording = false

      
    public var body: some View {
        
        ZStack {
            
            RoundedRectangle(cornerRadius: 35)
                .fill(.black.opacity(0.1)
                    .shadow(.inner(color: Color(hex : "#383838"), radius: 1, x: 0, y: -1))
                    .shadow(.inner(color: .black.opacity(0.61), radius: 2, x: 0, y: 2))
                )
                .background(.regularMaterial)
                .cornerRadius(35)
                .frame(height : 60)
            

            HStack {
                
                Spacer()
                
                if text.isEmpty {
                    Button {
                        if isRecording {
                            self.stopRecording()
                        } else {
                            // This will check for permissions and start recording if granted
                            self.requestAuthorizationAndStartRecording()
                            isRecording = true
                        }
                    } label: {
                        if isRecording {
                            LottieView(animation: .named("waveform"))
                              .playing()
                              .looping()
                              .resizable()
                              .scaledToFit()
                              .frame(width : 30, height :20)
                        }
                        Image(systemName : "mic.fill")
                            .font(.system(size: 17, weight : .medium))
                            .foregroundColor(isRecording ? .indigo : .white.opacity(0.23))
                    }
                    
                } else {
                    Button(action: {
                        text = ""
                        self.stopRecording()
                        hideKeyboard()
                    }, label: {
                        Image(systemName: "xmark.circle")
                    })
                }
            }
            .padding(.trailing, 20)
            
            HStack {
                Image(systemName : "magnifyingglass")
                    .font(.system(size: 17, weight : .medium))
                    .foregroundColor(.white.opacity(0.23))
                    .padding(.leading, 20)
                Spacer()
            }
            
            TextField("Search", text: $text, onCommit: {
                onSubmit()
                isEditing = false
            })
            .font(.system(size: 17, weight : .medium))
            .foregroundStyle(.white.opacity(0.23))
            .padding(.horizontal, 50)
            .textFieldStyle(.plain)

        }
        
    }
}
#endif



extension SearchField {
    func requestAuthorizationAndStartRecording() {
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    // Request microphone access authorization
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                // Both permissions are granted, start recording
                                try? self.startRecording()
                                print("Microphone granted.")

                            } else {
                                // Handle the microphone access denied case
                                print("Microphone access was not granted.")
                            }
                        }
                    }
                default:
                    // Handle the speech recognition access denied case
                    print("Speech recognition authorization was not granted.")
                }
            }
        }
    }
    
    func startRecording() throws {
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
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result, !result.bestTranscription.formattedString.isEmpty {
                // Only update if there's a non-empty transcription
                text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                stopRecording()

                self.recognitionRequest = nil
                self.recognitionTask = nil
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

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false

    }
}


#Preview {
    SearchFieldView()
}
