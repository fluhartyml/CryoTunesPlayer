//
//  PlaylistManager.swift
//  CryoTunes Player
//
//  Manages per-station thumbs-up playlists and the Shazamed Songs playlist
//  in the user's Apple Music library.
//

import Foundation
import MusicKit

@Observable
final class PlaylistManager {

    /// Cache of playlist names → Playlist objects to avoid repeated lookups
    private var cache: [String: Playlist] = [:]

    // MARK: - Public API

    /// Add a song to the "Shazamed Songs" playlist
    func addToShazamPlaylist(_ song: Song) async {
        let name = "Shazamed Songs"
        let description = "Songs identified by CryoTunes Player"
        await addSong(song, toPlaylistNamed: name, description: description)
    }

    /// Create an album playlist with all the album's tracks (skips if already exists)
    func addAlbumPlaylist(_ album: Album) async {
        guard let title = album.title as String? else { return }
        let name = "\(title) - \(album.artistName)"
        let description = "Album playlist created by CryoTunes Player"
        do {
            // REM: review 011 (2026-11-24): the comment above always promised "skips if
            // REM: already exists", but findOrCreate found the playlist and every track was
            // REM: added again on each play. An existing album playlist is now left alone.
            if cache[name] != nil { return }
            var existing = MusicLibraryRequest<Playlist>()
            existing.filter(matching: \.name, equalTo: name)
            if let found = try await existing.response().items.first {
                cache[name] = found
                return
            }
            let playlist = try await findOrCreate(name: name, description: description)
            if let tracks = album.tracks {
                for track in tracks {
                    try await Self.libraryAdd(track, to: playlist)
                }
            }
        } catch {
            print("PlaylistManager: failed to create album playlist \"\(name)\": \(error)")
        }
    }

    /// Add a song to a per-station thumbs-up playlist (e.g., "Jazz - CryoTunes")
    func addToStationPlaylist(_ song: Song, station: MusicStationOption) async {
        let name = "\(station.rawValue) - CryoTunes"
        let description = "Liked songs from \(station.rawValue) on CryoTunes Player"
        await addSong(song, toPlaylistNamed: name, description: description)
    }

    // MARK: - Private

    private func addSong(_ song: Song, toPlaylistNamed name: String, description: String) async {
        do {
            let playlist = try await findOrCreate(name: name, description: description)
            // Check if song is already in the playlist
            let detailed = try await playlist.with([.tracks])
            if let tracks = detailed.tracks, tracks.contains(where: { $0.id == song.id }) {
                return // Already in playlist, skip
            }
            try await Self.libraryAdd(song, to: playlist)
        } catch {
            print("PlaylistManager: failed to add song to \"\(name)\": \(error)")
        }
    }

    private func findOrCreate(name: String, description: String) async throws -> Playlist {
        if let cached = cache[name] { return cached }

        // Search the user's library for an existing playlist with this name
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.name, equalTo: name)
        let response = try await request.response()

        if let existing = response.items.first {
            cache[name] = existing
            return existing
        }

        // Create a new playlist
        let created = try await Self.libraryCreatePlaylist(name: name, description: description)
        cache[name] = created
        return created
    }

    // REM 11-18: MusicKit's library writes (add, createPlaylist) are iOS-only —
    // "unavailable in macOS". On the Mac these throw instead, so nothing is written.
    struct LibraryWriteUnavailable: Error {}

    private static func libraryAdd(_ track: Track, to playlist: Playlist) async throws {
        #if os(iOS) || os(visionOS)
        try await MusicLibrary.shared.add(track, to: playlist)
        #else
        throw LibraryWriteUnavailable()
        #endif
    }

    private static func libraryAdd(_ song: Song, to playlist: Playlist) async throws {
        #if os(iOS) || os(visionOS)
        try await MusicLibrary.shared.add(song, to: playlist)
        #else
        throw LibraryWriteUnavailable()
        #endif
    }

    /// Adds a song to the user's library (iOS only; throws on the Mac).
    static func libraryAddSong(_ song: Song) async throws {
        #if os(iOS) || os(visionOS)
        try await MusicLibrary.shared.add(song)
        #else
        throw LibraryWriteUnavailable()
        #endif
    }

    /// Adds an album to the user's library (iOS only; throws on the Mac).
    static func libraryAddAlbum(_ album: Album) async throws {
        #if os(iOS) || os(visionOS)
        try await MusicLibrary.shared.add(album)
        #else
        throw LibraryWriteUnavailable()
        #endif
    }

    private static func libraryCreatePlaylist(name: String, description: String) async throws -> Playlist {
        #if os(iOS) || os(visionOS)
        return try await MusicLibrary.shared.createPlaylist(name: name, description: description)
        #else
        throw LibraryWriteUnavailable()
        #endif
    }
}
