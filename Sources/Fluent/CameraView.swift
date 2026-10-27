import SwiftUI
import AVFoundation

struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        let l = AVCaptureVideoPreviewLayer(session: session)
        l.videoGravity = .resizeAspect
        v.layer = l
        v.wantsLayer = true
        return v
    }

    func updateNSView(_ v: NSView, context: Context) {}
}

@MainActor
final class CameraModel: ObservableObject {
    let session = AVCaptureSession()
    @Published var running = false
    @Published var denied = false
    @Published var name = ""
    @Published var size = ""

    func start() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else {
            denied = true
            return
        }
        guard let dev = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: dev) else {
            name = "No camera found"
            return
        }
        if session.inputs.isEmpty, session.canAddInput(input) { session.addInput(input) }
        let d = dev.activeFormat.formatDescription.dimensions
        name = dev.localizedName
        size = "\(d.width) × \(d.height)"
        let s = session
        await Task.detached { s.startRunning() }.value
        running = true
    }

    func stop() {
        let s = session
        Task.detached { s.stopRunning() }
        running = false
    }
}

struct CameraView: View {
    @StateObject private var cam = CameraModel()

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.primary.opacity(0.07))
                if cam.running { CameraPreview(session: cam.session).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)) }
                else { Image(systemName: "camera").font(.system(size: 56)).foregroundStyle(.secondary) }
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .frame(maxWidth: 640)
            if cam.denied {
                Text("Camera access is off. Allow it in Privacy & Security.").foregroundStyle(.secondary)
            } else if cam.running {
                Text("\(cam.name), \(cam.size)").foregroundStyle(.secondary)
                Button("Stop") { cam.stop() }.buttonStyle(.glass)
            } else {
                Button("Start Camera") { Task { await cam.start() } }.buttonStyle(.glassProminent).controlSize(.large)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Camera")
        .onDisappear { if cam.running { cam.stop() } }
    }
}
