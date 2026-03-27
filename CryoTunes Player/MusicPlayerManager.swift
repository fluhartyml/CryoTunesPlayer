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
    var currentStation: MusicStationOption = .none {
        didSet {
            UserDefaults.standard.set(currentStation.rawValue, forKey: "lastStation")
        }
    }
    var isPlaying = false
    var nowPlayingTitle = "" {
        didSet {
            UserDefaults.standard.set(nowPlayingTitle, forKey: "lastNowPlayingTitle")
        }
    }
    var currentSongTitle = ""
    var currentArtistName = ""
    var currentArtworkURL: URL?
    var sleepTimerEnd: Date?
    var sleepTimerRemaining = ""
    var isAuthorized = false
    var errorMessage = ""




    private let player = ApplicationMusicPlayer.shared
    private var timerTask: Task<Void, Never>?
    private var nowPlayingTask: Task<Void, Never>?

    init() {
        // Restore last station without auto-playing
        if let savedStation = UserDefaults.standard.string(forKey: "lastStation"),
           let station = MusicStationOption(rawValue: savedStation),
           station != .none {
            currentStation = station
            nowPlayingTitle = UserDefaults.standard.string(forKey: "lastNowPlayingTitle") ?? station.rawValue
        }
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
            await MainActor.run {
                errorMessage = "Unable to play station. Check your connection."
            }
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
        } else if player.state.playbackStatus == .paused {
            Task {
                try? await player.play()
                await MainActor.run { isPlaying = true }
            }
        } else if currentStation != .none {
            // Nothing loaded yet — start the saved station
            Task {
                await play(station: currentStation)
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

    // MARK: - Library Playback

    var libraryPlaylists: [Playlist] = []
    var libraryAlbums: [Album] = []
    var libraryArtists: [Artist] = []
    var librarySongs: [Song] = []

    func loadLibrary() async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            var playlistRequest = MusicLibraryRequest<Playlist>()
            playlistRequest.sort(by: \.name, ascending: true)
            let playlistResponse = try await playlistRequest.response()

            var albumRequest = MusicLibraryRequest<Album>()
            albumRequest.sort(by: \.title, ascending: true)
            let albumResponse = try await albumRequest.response()

            var artistRequest = MusicLibraryRequest<Artist>()
            artistRequest.sort(by: \.name, ascending: true)
            let artistResponse = try await artistRequest.response()

            await MainActor.run {
                libraryPlaylists = Array(playlistResponse.items)
                libraryAlbums = Array(albumResponse.items)
                libraryArtists = Array(artistResponse.items)
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to load library. Check your connection." }
        }
    }

    func loadSongs(for album: Album) async {
        do {
            let detailedAlbum = try await album.with([.tracks])
            let tracks = detailedAlbum.tracks ?? []
            await MainActor.run {
                librarySongs = tracks.compactMap { track in
                    if case let .song(song) = track { return song }
                    return nil
                }
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to load songs. Check your connection." }
        }
    }

    func loadSongs(for artist: Artist) async {
        do {
            var request = MusicLibraryRequest<Song>()
            request.filter(matching: \.artistName, equalTo: artist.name)
            request.sort(by: \.title, ascending: true)
            let response = try await request.response()
            await MainActor.run {
                librarySongs = Array(response.items)
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to load songs. Check your connection." }
        }
    }

    func playLibraryItem(_ item: any MusicCatalogSearchable & PlayableMusicItem) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            player.queue = [item]
            try await player.prepareToPlay()
            try await player.play()
            await MainActor.run {
                currentStation = .none
                isPlaying = true
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to play. Check your connection." }
        }
    }

    func playPlaylist(_ playlist: Playlist) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            player.queue = [playlist]
            try await player.prepareToPlay()
            try await player.play()
            await MainActor.run {
                currentStation = .none
                nowPlayingTitle = playlist.name
                isPlaying = true
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to play. Check your connection." }
        }
    }

    func playAlbum(_ album: Album) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            player.queue = [album]
            try await player.prepareToPlay()
            try await player.play()
            await MainActor.run {
                currentStation = .none
                nowPlayingTitle = album.title
                isPlaying = true
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to play. Check your connection." }
        }
    }

    func playSong(_ song: Song) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            player.queue = [song]
            try await player.prepareToPlay()
            try await player.play()
            await MainActor.run {
                currentStation = .none
                nowPlayingTitle = song.title
                isPlaying = true
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to play. Check your connection." }
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
