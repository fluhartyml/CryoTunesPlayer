//
//  CryoAppIntents.swift
//  CryoTunes Player
//
//  Siri / Shortcuts / Spotlight / Action Button / Control Center control via
//  App Intents. App Intents are iOS 16+, so this works on iOS 26 and 27 alike.
//  App-target only — drives the public CryoKit player API; no CryoKit change.
//

import AppIntents

/// Shared player so Siri-driven intents and the on-screen UI control the SAME
/// playback and state. `MusicPlaybackManager` wraps `ApplicationMusicPlayer.shared`.
enum CryoPlayerHost {
    static let player = MusicPlaybackManager()
}

// MARK: - Station entity (lets Siri resolve "play the Jazz station")

struct StationAppEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Station"
    static let defaultQuery = StationQuery()

    /// `MusicStationOption.savedKey` (permanent, review 044); `name` is the display name Siri says.
    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct StationQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [StationAppEntity] {
        identifiers.compactMap { id in
            MusicStationOption(rawValue: id).map { StationAppEntity(id: $0.savedKey, name: $0.displayName) }
        }
    }

    func suggestedEntities() async throws -> [StationAppEntity] {
        MusicStationOption.allCases
            .filter { $0 != .none }
            .map { StationAppEntity(id: $0.savedKey, name: $0.displayName) }
    }
}

// MARK: - Play a station

struct PlayStationIntent: AppIntent {
    static let title: LocalizedStringResource = "Play a CryoTunes Station"
    static let description = IntentDescription("Start one of CryoTunes' stations.")
    static let openAppWhenRun = false

    @Parameter(title: "Station")
    var station: StationAppEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let option = MusicStationOption(rawValue: station.id) else {
            return .result(dialog: "I couldn't find that station.")
        }
        let player = CryoPlayerHost.player
        await player.play(station: option)
        // REM: review 045 (2026-11-24, his "okay lock it") — Siri used to say "Playing …" even
        // REM: when the station failed. Same check as review 003: after the play call, only a
        // REM: player that is playing THIS station with no error counts as playing.
        guard player.isPlaying, player.currentStation == option, player.errorMessage.isEmpty else {
            return .result(dialog: "\(station.name) isn't available right now.")
        }
        return .result(dialog: "Playing \(station.name) on CryoTunes.")
    }
}

// MARK: - Transport

struct PlayPauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Play or Pause CryoTunes"
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        CryoPlayerHost.player.togglePlayPause()
        return .result()
    }
}

struct SkipIntent: AppIntent {
    static let title: LocalizedStringResource = "Skip to Next Track"
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        CryoPlayerHost.player.skipForward()
        return .result()
    }
}

struct StopPlaybackIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop CryoTunes"
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        CryoPlayerHost.player.stop()
        return .result()
    }
}

// MARK: - Sleep timer

enum SleepDurationOption: Int, AppEnum {
    // REM: review 040 (2026-11-24): a timer set by voice can be ended by voice, and
    // REM: "end of this song" is offered too.
    case off = 0
    case endOfSong = -1
    case thirty = 30
    case sixty = 60
    case twoHours = 120
    case fourHours = 240

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Sleep Duration"
    static let caseDisplayRepresentations: [SleepDurationOption: DisplayRepresentation] = [
        .off: "Off",
        .endOfSong: "End of this song",
        .thirty: "30 minutes",
        .sixty: "1 hour",
        .twoHours: "2 hours",
        .fourHours: "4 hours"
    ]
}

struct SleepTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Set CryoTunes Sleep Timer"
    static let openAppWhenRun = false

    @Parameter(title: "Duration")
    var duration: SleepDurationOption

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        CryoPlayerHost.player.startSleepTimer(minutes: duration.rawValue)
        switch duration {
        case .off: return .result(dialog: "Sleep timer is off.")
        case .endOfSong: return .result(dialog: "Music will stop at the end of this song.")
        default: return .result(dialog: "Sleep timer set for \(duration.rawValue) minutes.")
        }
    }
}

struct SleepTimerOffIntent: AppIntent {
    static let title: LocalizedStringResource = "Turn Off CryoTunes Sleep Timer"
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        CryoPlayerHost.player.startSleepTimer(minutes: 0)
        return .result(dialog: "Sleep timer is off.")
    }
}

// MARK: - Now playing

struct NowPlayingIntent: AppIntent {
    static let title: LocalizedStringResource = "What's Playing on CryoTunes"
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let title = CryoPlayerHost.player.currentSongTitle
        let artist = CryoPlayerHost.player.currentArtistName
        guard !title.isEmpty else {
            return .result(dialog: "Nothing is playing right now.")
        }
        let who = artist.isEmpty ? "" : " by \(artist)"
        return .result(dialog: "Now playing \(title)\(who).")
    }
}

// MARK: - Spoken shortcuts (Siri / Spotlight / Shortcuts app)

struct CryoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayStationIntent(),
            phrases: [
                "Play \(\.$station) on \(.applicationName)",
                "Start \(\.$station) on \(.applicationName)",
                "Play a station on \(.applicationName)"
            ],
            shortTitle: "Play Station",
            systemImageName: "music.note.list"
        )
        AppShortcut(
            intent: PlayPauseIntent(),
            phrases: [
                "Play or pause \(.applicationName)",
                "Pause \(.applicationName)"
            ],
            shortTitle: "Play / Pause",
            systemImageName: "playpause.fill"
        )
        AppShortcut(
            intent: SkipIntent(),
            phrases: [
                "Skip on \(.applicationName)",
                "Next track on \(.applicationName)"
            ],
            shortTitle: "Skip",
            systemImageName: "forward.end.fill"
        )
        AppShortcut(
            intent: StopPlaybackIntent(),
            phrases: ["Stop \(.applicationName)"],
            shortTitle: "Stop",
            systemImageName: "stop.fill"
        )
        AppShortcut(
            intent: NowPlayingIntent(),
            phrases: ["What's playing on \(.applicationName)"],
            shortTitle: "Now Playing",
            systemImageName: "info.circle"
        )
        AppShortcut(
            intent: SleepTimerIntent(),
            phrases: ["Set a sleep timer on \(.applicationName)"],
            shortTitle: "Sleep Timer",
            systemImageName: "moon.zzz.fill"
        )
        AppShortcut(
            intent: SleepTimerOffIntent(),
            phrases: [
                "Turn off the sleep timer on \(.applicationName)",
                "Cancel the sleep timer on \(.applicationName)"
            ],
            shortTitle: "Timer Off",
            systemImageName: "moon.zzz"
        )
    }
}
