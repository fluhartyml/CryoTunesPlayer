//
//  MusicPlayerManager.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import Foundation
import MusicKit
import MediaPlayer
import Combine

@Observable
class MusicPlayerManager {
    var currentStation: MusicStationOption = .none
    var isPlaying = false
    var nowPlayingTitle = ""
    var currentSongTitle = ""
    var currentArtistName = ""
    var currentArtworkURL: URL?
    var sleepTimerEnd: Date?
    var sleepTimerRemaining = ""
    var isAuthorized = false

    private let player = ApplicationMusicPlayer.shared
    private var timerTask: Task<Void, Never>?
    private var nowPlayingTask: Task<Void, Never>?

    init() {
        startNowPlayingObserver()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        await MainActor.run { isAuthorized = status == .authorized }
        return status == .authorized
    }

    // MARK: - Playback

    func play(station: MusicStationOption) async {
        guard station != .none else {
            stop()
            return
        }

        let authorized = await requestAuthorization()
        guard authorized else { return }

        if station.shouldRepeat {
            player.state.repeatMode = .all
        } else {
            player.state.repeatMode = MusicPlayer.RepeatMode.none
        }

        let term = station.searchTerm
        var name = station.rawValue

        do {
            switch station.searchType {
            case .stationFirst:
                if let result = try await searchStation(term: term) {
                    name = result
                } else if let result = try await searchPlaylist(term: term) {
                    name = result
                }
            case .stationOnly:
                if let result = try await searchStation(term: term) {
                    name = result
                }
            case .playlistFirst:
                if let result = try await searchPlaylist(term: term) {
                    name = result
                } else if let result = try await searchStation(term: term) {
                    name = result
                }
            case .albumFirst:
                if let result = try await searchAlbum(term: term) {
                    name = result
                } else if let result = try await searchPlaylist(term: term) {
                    name = result
                }
            }

            await MainActor.run {
                currentStation = station
                nowPlayingTitle = name
                isPlaying = true
            }
        } catch {
            print("Playback error: \(error)")
        }
    }

    private func searchStation(term: String) async throws -> String? {
        var request = MusicCatalogSearchRequest(term: term, types: [Station.self])
        request.limit = 1
        let response = try await request.response()
        guard let station = response.stations.first else { return nil }
        player.queue = [station]
        try await player.prepareToPlay()
        try await player.play()
        return station.name
    }

    private func searchPlaylist(term: String) async throws -> String? {
        var request = MusicCatalogSearchRequest(term: term, types: [Playlist.self])
        request.limit = 1
        let response = try await request.response()
        guard let playlist = response.playlists.first else { return nil }
        player.queue = [playlist]
        try await player.prepareToPlay()
        try await player.play()
        return playlist.name
    }

    private func searchAlbum(term: String) async throws -> String? {
        var request = MusicCatalogSearchRequest(term: term, types: [Album.self])
        request.limit = 1
        let response = try await request.response()
        guard let album = response.albums.first else { return nil }
        player.queue = [album]
        try await player.prepareToPlay()
        try await player.play()
        return album.title
    }

    func stop() {
        player.stop()
        currentStation = MusicStationOption.none
        isPlaying = false
        nowPlayingTitle = ""
        currentSongTitle = ""
        currentArtistName = ""
        currentArtworkURL = nil
    }

    func togglePlayPause() {
        if player.state.playbackStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            Task {
                try? await player.play()
                await MainActor.run { isPlaying = true }
            }
        }
    }

    func skipForward() {
        Task {
            try? await player.skipToNextEntry()
        }
    }

    func skipBack() {
        Task {
            try? await player.skipToPreviousEntry()
        }
    }

    // MARK: - Now Playing Observer

    private func startNowPlayingObserver() {
        nowPlayingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let entry = self.player.queue.currentEntry
                if let entry {
                    self.currentSongTitle = entry.title
                    self.currentArtistName = entry.subtitle ?? ""
                    if let artwork = entry.artwork {
                        self.currentArtworkURL = artwork.url(width: 300, height: 300)
                    }
                }
                self.isPlaying = self.player.state.playbackStatus == .playing
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    // MARK: - Sleep Timer

    func startSleepTimer(minutes: Int) {
        if minutes == 0 {
            sleepTimerEnd = nil
            sleepTimerRemaining = ""
            timerTask?.cancel()
            return
        }

        sleepTimerEnd = Date().addingTimeInterval(Double(minutes) * 60)
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let end = self.sleepTimerEnd else { return }
                let remaining = end.timeIntervalSinceNow
                if remaining <= 0 {
                    self.stop()
                    self.sleepTimerEnd = nil
                    self.sleepTimerRemaining = ""
                    return
                }
                let mins = Int(remaining) / 60
                let secs = Int(remaining) % 60
                self.sleepTimerRemaining = String(format: "%d:%02d", mins, secs)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
