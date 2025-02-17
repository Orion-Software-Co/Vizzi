import UIKit
import ARKit
import SceneKit
import SwiftUI

// MARK: - ARSCNView Subclass to Display a Point Cloud

/// A custom ARSCNView that configures an AR session with scene depth (LiDAR)
/// and updates a point cloud overlay from each frame.
class PointCloudARView: ARSCNView, ARSessionDelegate {
    
    /// Node used to display the point cloud.
    private var pointCloudNode: SCNNode?
    
    // MARK: Initialization
    
    override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        setupView()
        setupSession()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupSession()
    }
    
    /// Basic SceneKit setup.
    private func setupView() {
        self.delegate = self
        self.autoenablesDefaultLighting = true
        self.automaticallyUpdatesLighting = true
        
        // Enable some debug options to verify that the scene is updating.
        self.debugOptions = [ .showFeaturePoints]
    }
    
    /// Configures and runs the AR session with scene depth enabled.
    private func setupSession() {
        let configuration = ARWorldTrackingConfiguration()
        // Support both raw and smoothed depth if available.
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            configuration.frameSemantics.insert(.smoothedSceneDepth)
        }
        self.session.delegate = self
        self.session.run(configuration)
    }
    
    // MARK: ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Ensure the frame has scene depth.
        guard let _ = frame.sceneDepth else {
            // You can print here if sceneDepth is nil to help debug.
            print("No scene depth available for this frame.")
            return
        }
        
        // Convert the depth map to a point cloud (with per‑point depth).
        let pointsWithDepth = convertDepthMapToPointCloud(frame: frame)
        print("Point cloud generated \(pointsWithDepth.count) points")
        
        // Update the point cloud geometry on the main thread.
        DispatchQueue.main.async {
            self.updatePointCloud(with: pointsWithDepth)
        }
    }
    
    // MARK: Depth Map to Point Cloud Conversion
    
    /// Converts the ARFrame’s scene depth into an array of 3D points (in world space)
    /// along with their raw depth values.
    private func convertDepthMapToPointCloud(frame: ARFrame) -> [(position: SIMD3<Float>, depth: Float)] {
        guard let sceneDepth = frame.sceneDepth else { return [] }
        let depthMap = sceneDepth.depthMap
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        // Camera intrinsics: fx, fy, and principal point (cx, cy)
        let intrinsics = frame.camera.intrinsics
        let fx = intrinsics[0,0]
        let fy = intrinsics[1,1]
        let cx = intrinsics[0,2]
        let cy = intrinsics[1,2]
        
        // Sample every nth pixel to keep point count reasonable.
        let step = 4
        var points: [(position: SIMD3<Float>, depth: Float)] = []
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else { return [] }
        let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let index = y * width + x
                let depth = floatBuffer[index]
                // Skip invalid depths.
                if depth == 0 { continue }
                
                // Convert pixel (x,y) plus depth into a 3D point in camera space.
                let X = (Float(x) - cx) / fx * depth
                let Y = (Float(y) - cy) / fy * depth
                let Z = depth
                let cameraPoint = SIMD3<Float>(X, Y, Z)
                
                // Transform the point from camera space to world space.
                let worldPoint4 = frame.camera.transform * SIMD4<Float>(cameraPoint, 1)
                let worldPoint = SIMD3<Float>(worldPoint4.x, worldPoint4.y, worldPoint4.z)
                points.append((position: worldPoint, depth: depth))
            }
        }
        
        return points
    }
    
    // MARK: Color Mapping
    
    /// Maps a depth value (in meters) to a color.
    /// Points that are nearer (0.1m) will be red, and those farther away (5.0m) blue.
    private func colorForDepth(_ depth: Float) -> SIMD4<Float> {
        let minDepth: Float = 0.1
        let maxDepth: Float = 5.0
        let clampedDepth = max(minDepth, min(depth, maxDepth))
        let t = (clampedDepth - minDepth) / (maxDepth - minDepth)
        // Interpolate: near = red (1,0,0), far = blue (0,0,1)
        return SIMD4<Float>(1 - t, 0, t, 1)
    }
    
    
    
    // MARK: Updating the Point Cloud Geometry
    
    /// Builds (or updates) a custom SCNGeometry from the given points and applies a shader
    /// modifier to render them as points with a fixed size.
    private func updatePointCloud(with points: [(position: SIMD3<Float>, depth: Float)]) {
        guard !points.isEmpty else { return }
        
        var vertexData = [Float]()
        var colorData = [Float]()
        for tuple in points {
            let pos = tuple.position
            vertexData.append(contentsOf: [pos.x, pos.y, pos.z])
            let color = colorForDepth(tuple.depth)
            colorData.append(contentsOf: [color.x, color.y, color.z, color.w])
        }
        let vertexCount = points.count
        
        // Create Data objects from the float arrays.
        let vertexDataSize = vertexData.count * MemoryLayout<Float>.size
        let vertexNSData = Data(bytes: vertexData, count: vertexDataSize)
        
        let colorDataSize = colorData.count * MemoryLayout<Float>.size
        let colorNSData = Data(bytes: colorData, count: colorDataSize)
        
        // Create a vertex source.
        let vertexSource = SCNGeometrySource(
            data: vertexNSData,
            semantic: .vertex,
            vectorCount: vertexCount,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 3
        )
        
        // Create a color source.
        let colorSource = SCNGeometrySource(
            data: colorNSData,
            semantic: .color,
            vectorCount: vertexCount,
            usesFloatComponents: true,
            componentsPerVector: 4,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float>.size * 4
        )
        
        // Create index data – one index per vertex.
        var indices = [Int32](0..<Int32(vertexCount))
        let indexDataSize = indices.count * MemoryLayout<Int32>.size
        let indexNSData = Data(bytes: indices, count: indexDataSize)
        
        // Create a geometry element with a .point primitive.
        let element = SCNGeometryElement(
            data: indexNSData,
            primitiveType: .point,
            primitiveCount: vertexCount,
            bytesPerIndex: MemoryLayout<Int32>.size
        )
        
        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])
        
        // Use a shader modifier to set the point size.
        let geometryModifier = """
        uniform float pointSize;
        #pragma body
        _geometry.pointSize = pointSize;
        """
        
        let fragmentModifier = """
        #pragma body
        _output.color = _geometry.color;
        """
        let material = SCNMaterial()
        material.shaderModifiers = [
            .geometry: geometryModifier,
            .fragment: fragmentModifier
        ]
        
        
        // Increase point size to 10 for improved visibility.
        material.setValue(NSNumber(value: 10.0), forKey: "pointSize")
        material.lightingModel = .constant
        // Disable writing to the depth buffer so that the points overlay the camera feed.
        material.writesToDepthBuffer = false
        geometry.firstMaterial = material
        
        // Update the node’s geometry (or create it if needed).
        if let node = pointCloudNode {
            node.geometry = geometry
        } else {
            let node = SCNNode(geometry: geometry)
            pointCloudNode = node
            self.scene.rootNode.addChildNode(node)
        }
    }
}

// Conform to ARSCNViewDelegate if additional SceneKit delegate methods are needed.
extension PointCloudARView: ARSCNViewDelegate { }

  
// MARK: - SwiftUI Integration

/// A UIViewRepresentable that embeds the ARSCNView in SwiftUI.
struct ARSCNViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> PointCloudARView {
        return PointCloudARView(frame: .zero)
    }
    
    func updateUIView(_ uiView: PointCloudARView, context: Context) {
        // No dynamic updates needed.
    }
}
