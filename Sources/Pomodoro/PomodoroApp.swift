import SwiftUI
import AppKit

// MARK: - Model

enum Phase: Equatable {
    case work, rest

    var duration: TimeInterval { self == .work ? 25 * 60 : 5 * 60 }
    var title: String { self == .work ? "Work" : "Break" }
    var next: Phase { self == .work ? .rest : .work }
}

enum TimerState: Equatable {
    case idle
    case running(Phase, end: Date)
    case ringing(finished: Phase)   // alarm is sounding, waiting for the user
}

final class PomodoroModel: ObservableObject {
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var remaining: TimeInterval = 0

    private var ticker: Timer?
    private let alarm: NSSound? = {
        let sound = NSSound(named: "Glass")
        sound?.loops = true
        return sound
    }()

    func start(_ phase: Phase) {
        stopAlarm()
        remaining = phase.duration
        state = .running(phase, end: Date().addingTimeInterval(phase.duration))

        ticker?.invalidate()
        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)   // keep ticking while menus are open
        ticker = t
        updateDockBadge()
    }

    /// Called when the user acknowledges the alarm: start the opposite phase.
    func acknowledge() {
        guard case .ringing(let finished) = state else { return }
        start(finished.next)
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
        stopAlarm()
        state = .idle
        remaining = 0
        updateDockBadge()
    }

    private func tick() {
        guard case .running(let phase, let end) = state else { return }
        remaining = max(0, end.timeIntervalSinceNow)
        updateDockBadge()
        if remaining <= 0 { ring(after: phase) }
    }

    private func ring(after phase: Phase) {
        ticker?.invalidate()
        ticker = nil
        state = .ringing(finished: phase)
        updateDockBadge()
        alarm?.play()
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
        NSApp.requestUserAttention(.criticalRequest)
    }

    private func stopAlarm() {
        alarm?.stop()
    }

    private func updateDockBadge() {
        switch state {
        case .idle: NSApp.dockTile.badgeLabel = nil
        case .running: NSApp.dockTile.badgeLabel = "\(Int((remaining / 60).rounded(.up)))m"
        case .ringing: NSApp.dockTile.badgeLabel = "!"
        }
    }
}

// MARK: - UI

struct ContentView: View {
    @EnvironmentObject var model: PomodoroModel

    var body: some View {
        VStack(spacing: 20) {
            switch model.state {
            case .idle:
                Text("Ready").font(.title2).foregroundStyle(.secondary)
                Text("--:--").font(.system(size: 64, weight: .light, design: .monospaced))
                HStack(spacing: 12) {
                    Button("Start Work (25 min)") { model.start(.work) }
                        .keyboardShortcut(.defaultAction)
                    Button("Start Break (5 min)") { model.start(.rest) }
                }

            case .running(let phase, _):
                Text(phase.title).font(.title2).foregroundStyle(phase == .work ? .red : .green)
                Text(format(model.remaining))
                    .font(.system(size: 64, weight: .light, design: .monospaced))
                Button("Stop", role: .destructive) { model.stop() }

            case .ringing(let finished):
                Text("\(finished.title) is over!").font(.title2).bold()
                Text("00:00").font(.system(size: 64, weight: .light, design: .monospaced))
                    .foregroundStyle(.orange)
                HStack(spacing: 12) {
                    Button("Start \(finished.next.title) (\(Int(finished.next.duration / 60)) min)") {
                        model.acknowledge()
                    }
                    .keyboardShortcut(.defaultAction)
                    Button("Stop", role: .destructive) { model.stop() }
                }
            }
        }
        .controlSize(.large)
        .padding(32)
        .frame(minWidth: 380)
    }

    private func format(_ t: TimeInterval) -> String {
        let s = Int(t.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)   // needed when run as a bare executable
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = PomodoroModel()

    var body: some Scene {
        Window("Pomodoro", id: "main") {
            ContentView().environmentObject(model)
        }
        .windowResizability(.contentSize)
    }
}
