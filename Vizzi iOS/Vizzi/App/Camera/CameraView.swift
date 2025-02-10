
import SwiftUI
import AVFoundation


struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var visionVM: VisionViewModel
    @EnvironmentObject var openAIVM: OpenAIViewModel
    @StateObject var imageUploadVM = ImageUploadViewModel()
    
    var body: some View {
        ZStack {
            if let capturedImage = cameraManager.capturedImage {
                // ✅ Show captured image instead of video preview
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .edgesIgnoringSafeArea(.all)
            } else {
                // ✅ Live camera preview
                CameraViewFinder(session: cameraManager.session)
                    .edgesIgnoringSafeArea(.all)
            }

            VStack {
                HStack {
                    Button(action: {
                        cameraManager.stopSession()
                        appManager.showCamera = false
                    }) {
                        CircleIconLabel(icon: "xmark")
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                Spacer()

                HStack {
                    
                    if !visionVM.imageAnalysisResult.isEmpty {
                        Text(visionVM.imageAnalysisResult)
                            .font(.SFBold.largeTitle)
                            .padding(30)
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.silk.opacity(0.2), lineWidth: 0.5)
                            }
                            .background(.regularMaterial)
                            .cornerRadius(20)
                            .shadow(color : .black.opacity(0.1), radius: 5, x: 0, y: 10)
                            .padding(.leading)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        generateHapticFeedback(style: .light)
                        cameraManager.capturePhoto()
                    }) {
                        ZStack {
                            Image(systemName: "camera.fill")
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
                    .padding(.trailing)
                }

                Spacer()
            }
        }
        .onAppear {
            cameraManager.checkCameraPermissions()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if let image = newImage {
                uploadCapturedImage(image)
                cameraManager.stopSession() // ✅ Stop camera after capturing
            }
        }
    }
    
    /// ✅ Upload the captured image immediately after taking it
    private func uploadCapturedImage(_ image: UIImage) {
        visionVM.captureImageAndDescribe(image: image, targetLocale: "en-US", openAIVM: openAIVM) 
    }
}


class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")

    @Published var capturedImage: UIImage? // Stores the captured image
    
    override init() {
        super.init()
    }
    
    /// ✅ Checks for camera permissions and sets up the session if allowed
    func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupSession()
                    } else {
                        print("Camera access denied.")
                    }
                }
            }
        default:
            print("Camera access denied.")
        }
    }
    
    /// ✅ Configures the capture session safely
    private func setupSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            defer { self.session.commitConfiguration() }
            
            self.session.sessionPreset = .photo
            
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("Error setting up camera input")
                return
            }
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            self.startSession()
        }
    }
    
    /// ✅ Starts the session after configuration is committed
    private func startSession() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    /// ✅ Stops the session
    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    /// ✅ Captures a photo
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// ✅ Processes the captured photo and stops the camera
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.capturedImage = image
                self.stopSession() // ✅ Stop the session immediately after capturing the photo
            }
        }
    }
}


/// ✅ SwiftUI-Compatible Camera View
struct CameraViewFinder: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    CameraView()
}
