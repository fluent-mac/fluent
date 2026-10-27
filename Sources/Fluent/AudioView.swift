import SwiftUI
import AVFoundation

final class Oscillator: @unchecked Sendable {
    var phase = 0.0
}

@MainActor
final class AudioModel: ObservableObject {
    enum Side: String, CaseIterable, Identifiable {
        case left = "Left", both = "Both", right = "Right"
        var id: String { rawValue }
        var pan: Float { self == .left ? -1 : (self == .right ? 1 : 0) }
    }

    @Published var playing: Side?
    @Published var level = 0.0
    @Published var micOn = false
    @Published var denied = false
    private let tone = AVAudioEngine()
    private let mic = AVAudioEngine()

    func play(_ side: Side) {
        stopTone()
        let sr = tone.outputNode.outputFormat(forBus: 0).sampleRate
        let osc = Oscillator()
        let src = AVAudioSourceNode { _, _, frames, abl -> OSStatus in
            let list = UnsafeMutableAudioBufferListPointer(abl)
            for f in 0..<Int(frames) {
                let v = Float(sin(osc.phase)) * 0.25
                osc.phase += 2 * .pi * 440 / sr
                if osc.phase > 2 * .pi { osc.phase -= 2 * .pi }
                for b in list { b.mData?.assumingMemoryBound(to: Float.self)[f] = v }
            }
            return noErr
        }
        tone.attach(src)
        tone.connect(src, to: tone.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1))
        src.pan = side.pan
        do { try tone.start() } catch { return }
        playing = side
    }

    func stopTone() {
        if tone.isRunning { tone.stop() }
        for n in tone.attachedNodes where n is AVAudioSourceNode { tone.detach(n) }
        playing = nil
    }

    func startMic() async {
        guard await AVCaptureDevice.requestAccess(for: .audio) else {
            denied = true
            return
        }
        let input = mic.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buf, _ in
            guard let ch = buf.floatChannelData?[0] else { return }
            let n = Int(buf.frameLength)
            var sum: Float = 0
            for i in 0..<n { sum += ch[i] * ch[i] }
            let rms = Double((sum / Float(max(1, n))).squareRoot())
            Task { @MainActor in self?.level = min(1, rms * 6) }
        }
        do { try mic.start(); micOn = true } catch { denied = true }
    }

    func stopMic() {
        mic.inputNode.removeTap(onBus: 0)
        mic.stop()
        micOn = false
        level = 0
    }

    func stopAll() {
        stopTone()
        if micOn { stopMic() }
    }
}

struct AudioView: View {
    @StateObject private var audio = AudioModel()

    var body: some View {
        Form {
            Section("Speakers") {
                HStack {
                    ForEach(AudioModel.Side.allCases) { s in
                        if audio.playing == s {
                            Button("Stop \(s.rawValue)") { audio.stopTone() }.buttonStyle(.glassProminent)
                        } else {
                            Button(s.rawValue) { audio.play(s) }.buttonStyle(.glass)
                        }
                    }
                }
            }
            Section("Microphone") {
                if audio.denied {
                    Text("Microphone access is off. Allow it in Privacy & Security.").foregroundStyle(.secondary)
                } else {
                    ProgressView(value: audio.level).animation(.linear(duration: 0.08), value: audio.level)
                    if audio.micOn {
                        Button("Stop") { audio.stopMic() }
                    } else {
                        Button("Start Listening") { Task { await audio.startMic() } }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Audio")
        .onDisappear { audio.stopAll() }
    }
}
