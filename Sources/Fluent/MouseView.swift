import SwiftUI
import AppKit
import FluentCore

struct MouseView: View {
    enum Test: String, CaseIterable, Identifiable {
        case buttons = "Buttons"
        case rate = "Polling Rate"
        case dpi = "DPI"
        var id: String { rawValue }
    }

    @State private var test = Test.buttons
    @State private var presses: [Int: Int] = [:]
    @State private var held: Set<Int> = []
    @State private var doubles = 0
    @State private var wheel = (x: 0.0, y: 0.0)
    @State private var estimator = PollingEstimator()
    @State private var topHz = 0.0
    @State private var cm = 10.0
    @State private var measuring = false
    @State private var travelled = 0.0
    @State private var counts: Double?

    var body: some View {
        VStack(spacing: 24) {
            pad
            readout
                .frame(maxWidth: 600)
            Spacer(minLength: 0)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Mouse")
        .toolbar {
            ToolbarItem {
                Picker("Test", selection: $test) {
                    ForEach(Test.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            ToolbarItem {
                Button("Reset") { reset() }
            }
        }
        .onChange(of: test) { reset() }
        .onAppear { NSEvent.isMouseCoalescingEnabled = false }
        .onDisappear { NSEvent.isMouseCoalescingEnabled = true }
    }

    private var pad: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.primary.opacity(0.06))
            .frame(maxWidth: 600, minHeight: 170, maxHeight: 220)
            .overlay {
                Text(hint).font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center).padding()
            }
            .overlay(EventCapture(handlers: handlers))
            .accessibilityLabel("Mouse test area")
    }

    private var hint: String {
        switch test {
        case .buttons: return "Press any mouse button or scroll here"
        case .rate: return "Move the pointer in circles"
        case .dpi: return measuring ? "Move the pointer in a straight line, then press Finish" : "Set the distance, press Start, then move the mouse that far"
        }
    }

    @ViewBuilder
    private var readout: some View {
        switch test {
        case .buttons: buttonsReadout
        case .rate: rateReadout
        case .dpi: dpiReadout
        }
    }

    private var buttonsReadout: some View {
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                chip("Left", 0)
                chip("Right", 1)
                chip("Middle", 2)
                chip("Back", 3)
                chip("Forward", 4)
            }
            Form {
                LabeledContent("Double clicks", value: "\(doubles)")
                LabeledContent("Wheel vertical", value: String(format: "%.0f", wheel.y))
                LabeledContent("Wheel horizontal", value: String(format: "%.0f", wheel.x))
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 170)
        }
    }

    private func chip(_ name: String, _ n: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(presses[n] ?? 0)").font(.title2.weight(.semibold)).monospacedDigit()
            Text(name).font(.callout)
        }
        .frame(width: 90, height: 70)
        .background(held.contains(n) ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var rateReadout: some View {
        Form {
            Section {
                if let hz = estimator.hz, let j = estimator.jitterMs {
                    LabeledContent("Reporting rate", value: "\(PollingEstimator.nearestStandard(hz)) Hz")
                    LabeledContent("Measured", value: String(format: "%.0f Hz", hz))
                    LabeledContent("Highest seen", value: String(format: "%.0f Hz", topHz))
                    LabeledContent("Interval jitter", value: String(format: "%.2f ms", j))
                } else {
                    Text("Keep moving the pointer").foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(height: 230)
    }

    private var dpiReadout: some View {
        Form {
            Section {
            LabeledContent("Distance") {
                HStack {
                    TextField("Distance", value: $cm, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                        .disabled(measuring)
                    Text("cm")
                }
            }
            if measuring {
                LabeledContent("Moved so far", value: String(format: "%.0f points", travelled))
                Button("Finish") { finishDPI() }
            } else {
                Button("Start") {
                    travelled = 0
                    counts = nil
                    measuring = true
                }
                .disabled(cm <= 0)
            }
            if let c = counts {
                let cpi = DPI.cpi(counts: c, inches: DPI.inches(fromCentimeters: cm))
                LabeledContent("Counts per inch", value: String(format: "%.0f", cpi))
                LabeledContent("Closest common setting", value: "\(DPI.nearestCommon(cpi)) DPI")
            }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(height: 300)
    }

    private var handlers: InputHandlers {
        var h = InputHandlers()
        h.mouseDown = { e in
            presses[e.buttonNumber, default: 0] += 1
            held.insert(e.buttonNumber)
            if e.clickCount == 2 { doubles += 1 }
        }
        h.mouseUp = { e in held.remove(e.buttonNumber) }
        h.mouseMoved = { e in
            if test == .rate {
                estimator.add(e.timestamp)
                if let hz = estimator.hz { topHz = max(topHz, hz) }
            }
            if measuring { travelled += hypot(e.deltaX, e.deltaY) }
        }
        h.scroll = { e in
            wheel.x += e.scrollingDeltaX
            wheel.y += e.scrollingDeltaY
        }
        return h
    }

    private func finishDPI() {
        measuring = false
        counts = travelled > 0 ? travelled : nil
    }

    private func reset() {
        presses = [:]
        held = []
        doubles = 0
        wheel = (0, 0)
        estimator.reset()
        topHz = 0
        measuring = false
        travelled = 0
        counts = nil
    }
}
