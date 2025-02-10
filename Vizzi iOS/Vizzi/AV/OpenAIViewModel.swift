
import SwiftUI
import Speech
import AVFoundation
@preconcurrency import OpenAI


struct ChatMessage: Identifiable {
    var id: UUID = UUID()
    var role: Role
    var content: String
    
    enum Role: String {
        case user = "user"
        case assistant = "assistant"
    }
}

enum Voice: String, CaseIterable, Identifiable {
    case alloy = "alloy"
    case echo = "echo"
    case fable = "fable"
    case onyx = "onyx"
    case nova = "nova"
    case shimmer = "shimmer"

    var id: String { self.rawValue }

    // Convert to API's voice type
    func toAPIVoice() -> AudioSpeechQuery.AudioSpeechVoice {
        return AudioSpeechQuery.AudioSpeechVoice(rawValue: self.rawValue) ?? .alloy
    }
}

struct VoiceOption: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
}


extension UserDefaults {
    static let selectedVoiceKey = "selectedVoice"
}


enum InputSelectionType {
    case voice, text, none
}



class OpenAIViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate, @unchecked Sendable {
    @Published var inputPreference: InputSelectionType = .none
    
    let openAI = OpenAI(apiToken: "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")
    @Published var query = ""
    @Published var voices = Voice.allCases
    
    @Published var selectedVoice: Voice {
        didSet {
            saveVoiceSelection()
        }
    }
    
    var audioPlayer: AVAudioPlayer?
    @Published var isAudioPlaying: Bool = false
    @Published var isResponding = false
    @Published var responsePending = false

    override init() {
        selectedVoice = UserDefaults.standard.string(forKey: UserDefaults.selectedVoiceKey)
            .flatMap { Voice(rawValue: $0) } ?? .alloy
                
        super.init()
        
    }

    private func saveVoiceSelection() {
        UserDefaults.standard.set(selectedVoice.rawValue, forKey: UserDefaults.selectedVoiceKey)
    }
    
    
    func classifyQuery(appManager: AppManager, mapVM: MapViewModel) async {
        DispatchQueue.main.async {
            self.responsePending = true
        }
        
        let promptString = """
        You are a classifier for a users query. If you determine that the user is requesting navigation to a location, respond in the following JSON:
        
        {
            "queryType" : "navigation",
            "destination" : "Golden Gate Bridge, San Francisco"
        }
        
        Otherwise, respond with the following JSON
        {
            "queryType" : "general"
        }
        """
        
        let systemMessage : ChatQuery.ChatCompletionMessageParam = .init(role: .assistant, content: promptString)!

        let chatQuery = ChatQuery(
            messages: [systemMessage, .init(role: .user, content: query)!],
            model: .gpt4_o,
            responseFormat: .jsonObject
        )
        
        do {
            let result = try await openAI.chats(query: chatQuery)
            DispatchQueue.main.async {
                if let firstChoice = result.choices.first,
                   case let .string(responseContent) = firstChoice.message.content {
                    self.handleClassificationResponse(responseContent, appManager: appManager, mapVM: mapVM)
                } else {
                    self.responsePending = false
                }
            }
        } catch {
            print("Failed to get response from OpenAI: \(error.localizedDescription)")
            self.responsePending = false
        }
    }
    
    func sendQuery(appManager : AppManager) async {
        let systemMessage : ChatQuery.ChatCompletionMessageParam = .init(role: .assistant, content: "You are Vizzi, a visual guide for the visually impaired. Please respond with relevant responses to the users queries that are excessively concise and factual")!

        let chatQuery = ChatQuery(
            messages: [systemMessage, .init(role: .user, content: query)!],
            model: .gpt4_o
        )
        
        do {
            let result = try await openAI.chats(query: chatQuery)
            DispatchQueue.main.async {
                if let firstChoice = result.choices.first,
                   case let .string(responseContent) = firstChoice.message.content {
                    Task {
                        await self.synthesizeResponse(from: responseContent)
                    }
                    
                    self.query = ""
                }
            }
        } catch {
            print("Failed to get response from OpenAI: \(error.localizedDescription)")
            self.responsePending = false
        }
    }
    
    private func handleClassificationResponse(_ responseContent: String, appManager : AppManager, mapVM: MapViewModel) {
        guard let data = responseContent.data(using: .utf8) else {
            print("Failed to parse responseContent to data")
            self.responsePending = false
            return
        }
        
        do {
            let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let queryType = responseJSON?["queryType"] as? String {
                if queryType == "navigation", let destination = responseJSON?["destination"] as? String {
                    print("Navigation to: \(destination)")
                    Task {
                        await self.handleNavigation(to: destination, appManager: appManager, mapVM: mapVM)
                    }
                } else if queryType == "general" {
                    Task {
                        await self.sendQuery(appManager: appManager)
                    }
                }
            }
        } catch {
            print("Failed to decode classification response: \(error.localizedDescription)")
        }
        self.responsePending = false
    }

    private func handleNavigation(to destination: String, appManager : AppManager, mapVM: MapViewModel) async {
        print("Handling navigation to \(destination)")
        let actionVM = ActionViewModel()
        let action = Action(category: .navigation, subtext: destination)
        actionVM.performNavigation(action: action, appManager: appManager, mapVM: mapVM)
        
        Task {
            await self.synthesizeResponse(from: "Sure, here's your walking route to \(destination)")
        }
        
        DispatchQueue.main.async {
            self.responsePending = false
            self.query = ""
        }
    }
    
    
    func synthesizeResponse(from text: String) async {
        let speechQuery = AudioSpeechQuery(
            model: .tts_1_hd,
            input: text,
            voice: selectedVoice.toAPIVoice(),
            responseFormat: .mp3,
            speed: 1.0
        )
        do {
            let speechResult = try await openAI.audioCreateSpeech(query: speechQuery)
            DispatchQueue.main.async {
                self.playAudio(from: speechResult.audio)
            }
        } catch {
            DispatchQueue.main.async {
                print("Error synthesizing speech: \(error)")
            }
        }
    }
    
    /// Prepares and manages the audio session for playback
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    /// Plays audio from given data.
    func playAudio(from data: Data) {
        setupAudioSession()
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            DispatchQueue.main.async {
                self.responsePending = false
                self.isResponding = true
                self.isAudioPlaying = true
            }
        } catch {
            print("Failed to play audio: \(error)")
            DispatchQueue.main.async {
                self.isResponding = false
                self.isAudioPlaying = false
            }
        }
    }

    /// Called when audio playback finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isResponding = false
            self.isAudioPlaying = false

        }
    }
    
    func stopAudio() {
        if audioPlayer?.isPlaying ?? false {
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            self.isResponding = false
        }
    }
}
