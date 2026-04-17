//
//  PlaylistManager.swift
//  CryoTunes Player
//
//  Manages per-station thumbs-up playlists and the Shazamed Songs playlist
//  in the user's Apple Music library.
//

import Foundation
import MusicKit
import CryoKit

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
            let playlist = try await findOrCreate(name: name, description: description)
            if let tracks = album.tracks {
                for track in tracks {
                    try await MusicLibrary.shared.add(track, to: playlist)
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
            try await MusicLibrary.shared.add(song, to: playlist)
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
        let created = try await MusicLibrary.shared.createPlaylist(name: name, description: description)
        cache[name] = created
        return created
    }
}
