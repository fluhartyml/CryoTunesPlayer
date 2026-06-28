//
//  StationFailureMonitor.swift
//  CryoTunes Player
//
//  Watches station-tap → playback transition; if music isn't actually
//  playing 3 seconds after a tap (and preflights pass), surfaces an
//  alert offering to email a diagnostic report to the developer.
//

import Foundation
import SwiftUI
import MusicKit
import MessageUI
import Network
import UIKit

@Observable
@MainActor
final class StationFailureMonitor {
    var pendingReport: StationReport?

    private var reportedThisSession: Set<MusicStationOption> = []
    private var currentTask: Task<Void, Never>?
    private let pathMonitor = NWPathMonitor()
    private var lastKnownPath: NWPath.Status = .satisfied

    init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.lastKnownPath = path.status
            }
        }
        pathMonitor.start(queue: .global(qos: .background))
    }

    /// Replaces a direct call to `player.play(station:)`. Plays the station,
    /// then 3 seconds later checks whether music is actually playing. If not
    /// (and bona-fide preflights pass), surfaces the alert.
    func monitorPlay(station: MusicStationOption, player: MusicPlaybackManager) async {
        currentTask?.cancel()
        currentTask = nil

        // Stop case: just play, no monitoring needed.
        if station == .none {
            await player.play(station: station)
            return
        }

        await player.play(station: station)

        currentTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(3))
            } catch {
                return
            }
            self.checkAndReport(station: station, player: player)
        }
    }

    private func checkAndReport(station: MusicStationOption, player: MusicPlaybackManager) {
        // User moved on to a different station.
        guard player.currentStation == station else { return }

        // ApplicationMusicPlayer.shared is the singleton CryoKit also uses,
        // so this reads the real playback state, not CryoKit's lying isPlaying.
        let status = ApplicationMusicPlayer.shared.state.playbackStatus
        if status == .playing { return }
        if status == .paused { return }  // user paused intentionally

        // Bona-fide filter
        if reportedThisSession.contains(station) { return }
        guard MusicAuthorization.currentStatus == .authorized else { return }
        guard lastKnownPath == .satisfied else { return }
        guard MFMailComposeViewController.canSendMail() else { return }

        reportedThisSession.insert(station)
        pendingReport = StationReport(station: station)
    }

    func dismiss() {
        pendingReport = nil
    }
}

struct StationReport: Identifiable {
    let id = UUID()
    let station: MusicStationOption
    let timestamp: Date

    init(station: MusicStationOption) {
        self.station = station
        self.timestamp = Date()
    }

    var emailSubject: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "CryoTunes Player broken station: \(station.rawValue) — v\(v) (\(b))"
    }

    var emailBody: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

        var sysinfo = utsname()
        uname(&sysinfo)
        let model = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0) ?? "Unknown"
            }
        }
        let device = UIDevice.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm zzz"

        let stationID = station.stationID ?? "(none)"
        let bucketLabel: String = {
            if let bucket = station.appleRadioBucket {
                return "Apple Radio / \(bucket.rawValue)"
            }
            return station.sourceType.rawValue
        }()

        return """
        Thank you for using CryoTunes Player and helping me make it
        the best app it can be. The info below tells me which station
        didn't load and what I need to fix.

        Station that didn't play:  \(station.rawValue)
        Source type:               \(bucketLabel)
        Search type:               \(String(describing: station.searchType))
        Search term:               \(station.searchTerm)
        Station ID:                \(stationID)

        App:     CryoTunes Player \(v) (\(b))
        Device:  \(model)
        System:  \(device.systemName) \(device.systemVersion)
        Time:    \(formatter.string(from: timestamp))

        —— Notes about the broken station (optional) ——


        —— Any other stations you'd like to see in CryoTunes? (optional) ——


        — Michael
        """
    }
}
