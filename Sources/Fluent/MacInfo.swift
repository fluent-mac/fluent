import SwiftUI
import AppKit
import FluentCore

enum Shell {
    static func run(_ path: String, _ args: [String]) async -> String {
        await Task.detached {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: path)
            p.arguments = args
            let out = Pipe()
            p.standardOutput = out
            p.standardError = Pipe()
            do { try p.run() } catch { return "" }
            let data = out.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            return String(data: data, encoding: .utf8) ?? ""
        }.value
    }

    static func json(_ type: String) async -> [String: Any] {
        let s = await run("/usr/sbin/system_profiler", [type, "-json"])
        guard let d = s.data(using: .utf8), let o = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return [:] }
        return o
    }
}

struct InfoRow: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    var level = Level.info
}

struct InfoSection: Identifiable {
    let id: String
    var rows: [InfoRow]
}

@MainActor
final class MacInfo: ObservableObject {
    @Published private(set) var sections: [InfoSection] = []
    @Published private(set) var loading = false

    var report: String {
        sections.map { s in
            s.id + "\n" + s.rows.map { "  \($0.label): \($0.value)" }.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    func load() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        async let hw = Shell.json("SPHardwareDataType")
        async let power = Shell.json("SPPowerDataType")
        async let displays = Shell.json("SPDisplaysDataType")
        async let fv = Shell.run("/usr/bin/fdesetup", ["status"])
        async let sip = Shell.run("/usr/bin/csrutil", ["status"])
        async let mdm = Shell.run("/usr/bin/profiles", ["status", "-type", "enrollment"])
        let (h, p, d, f, s, m) = await (hw, power, displays, fv, sip, mdm)

        var out: [InfoSection] = []
        let hard = (h["SPHardwareDataType"] as? [[String: Any]])?.first ?? [:]
        func str(_ k: String) -> String? { hard[k] as? String }
        var hr: [InfoRow] = []
        if let v = str("machine_name") { hr.append(InfoRow(label: "Model", value: v)) }
        if let v = str("machine_model") { hr.append(InfoRow(label: "Identifier", value: v)) }
        if let v = str("chip_type") ?? str("cpu_type") { hr.append(InfoRow(label: "Chip", value: v)) }
        if let v = str("number_processors") { hr.append(InfoRow(label: "Cores", value: v)) }
        if let v = str("physical_memory") { hr.append(InfoRow(label: "Memory", value: v)) }
        if let v = str("serial_number") { hr.append(InfoRow(label: "Serial number", value: v)) }
        hr.append(InfoRow(label: "macOS", value: ProcessInfo.processInfo.operatingSystemVersionString))
        out.append(InfoSection(id: "Hardware", rows: hr))

        var bat: [InfoRow] = []
        let items = p["SPPowerDataType"] as? [[String: Any]] ?? []
        if let b = items.first(where: { $0["sppower_battery_health_info"] != nil }),
           let info = b["sppower_battery_health_info"] as? [String: Any] {
            let cycles = info["sppower_battery_cycle_count"] as? Int
            let cap = Health.percent(info["sppower_battery_health_maximum_capacity"] as? String)
            let lvl = Health.battery(cycles: cycles, capacity: cap)
            if let c = cycles { bat.append(InfoRow(label: "Charge cycles", value: "\(c)", level: lvl == .warn ? .warn : .info)) }
            if let c = cap { bat.append(InfoRow(label: "Maximum capacity", value: "\(c)%", level: lvl)) }
            if let c = info["sppower_battery_health"] as? String { bat.append(InfoRow(label: "Condition", value: c)) }
        } else {
            bat.append(InfoRow(label: "Battery", value: "None found"))
        }
        out.append(InfoSection(id: "Battery", rows: bat))

        var sto: [InfoRow] = []
        if let a = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let total = a[.systemSize] as? Int64, let free = a[.systemFreeSize] as? Int64 {
            let fmt = ByteCountFormatter()
            sto.append(InfoRow(label: "Capacity", value: fmt.string(fromByteCount: total)))
            sto.append(InfoRow(label: "Free", value: fmt.string(fromByteCount: free), level: Health.storage(free: free, total: total)))
        }
        out.append(InfoSection(id: "Storage", rows: sto))

        var sec: [InfoRow] = []
        if let v = str("activation_lock_status") {
            let on = v.lowercased().contains("enabled") && !v.lowercased().contains("disabled")
            sec.append(InfoRow(label: "Activation Lock", value: on ? "On" : "Off", level: on ? .bad : .good))
        }
        let mdmOn = m.contains("MDM enrollment: Yes") || m.contains("Enrolled via DEP: Yes")
        sec.append(InfoRow(label: "Remote management", value: m.isEmpty ? "Unavailable" : (mdmOn ? "Enrolled" : "Not enrolled"), level: m.isEmpty ? .info : (mdmOn ? .bad : .good)))
        sec.append(InfoRow(label: "FileVault", value: f.isEmpty ? "Unavailable" : (f.contains("On") ? "On" : "Off")))
        sec.append(InfoRow(label: "System Integrity Protection", value: s.isEmpty ? "Unavailable" : (s.contains("enabled") ? "On" : "Off"), level: s.contains("disabled") ? .warn : .info))
        out.append(InfoSection(id: "Security", rows: sec))

        var disp: [InfoRow] = []
        for g in d["SPDisplaysDataType"] as? [[String: Any]] ?? [] {
            for n in g["spdisplays_ndrvs"] as? [[String: Any]] ?? [] {
                let name = n["_name"] as? String ?? "Display"
                let res = n["_spdisplays_resolution"] as? String ?? n["spdisplays_resolution"] as? String ?? ""
                disp.append(InfoRow(label: name, value: res))
            }
        }
        if !disp.isEmpty { out.append(InfoSection(id: "Displays", rows: disp)) }
        sections = out
    }
}
