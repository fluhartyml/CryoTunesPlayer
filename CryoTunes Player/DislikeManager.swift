//
//  DislikeManager.swift
//  CryoTunes Player
//
//  Per-station dislike tracking. When a user skips or thumbs-down a song,
//  it's remembered for that station and auto-skipped next time.
//

import Foundation
import MusicKit
import CryoKit

@Observable
final class DislikeManager {
    /// Dictionary: station rawValue → Set of disliked song ID strings
    private(set) var dislikes: [String: Set<String>] = [:]

    /// Tracks the last disliked song for undo via previous-track
    private(set) var lastDislike: (station: String, songID: String)?

    private let storageKey = "stationDislikes"

    init() {
        load()
    }

    // MARK: - Public API

    /// Record a dislike for the current song on the current station
    func dislike(songID: String, on station: MusicStationOption) {
        let key = station.rawValue
        var set = dislikes[key] ?? []
        set.insert(songID)
        dislikes[key] = set
        lastDislike = (station: key, songID: songID)
        save()
    }

    /// Undo the last dislike (previous-track within song window)
    func undoLastDislike() {
        guard let last = lastDislike else { return }
        dislikes[last.station]?.remove(last.songID)
        if dislikes[last.station]?.isEmpty == true {
            dislikes.removeValue(forKey: last.station)
        }
        lastDislike = nil
        save()
    }

    /// Clear the undo window (called when a song ends naturally)
    func clearUndo() {
        lastDislike = nil
    }

    /// Check if a song is disliked on a given station
    func isDisliked(songID: String, on station: MusicStationOption) -> Bool {
        dislikes[station.rawValue]?.contains(songID) == true
    }

    /// Reset dislikes for a specific station
    func resetStation(_ station: MusicStationOption) {
        dislikes.removeValue(forKey: station.rawValue)
        save()
    }

    /// Reset all dislikes across all stations
    func resetAll() {
        dislikes.removeAll()
        lastDislike = nil
        save()
    }

    /// Stations that have dislikes, sorted by name
    func stationsWithDislikes() -> [(station: MusicStationOption, count: Int)] {
        dislikes.compactMap { key, songIDs in
            guard !songIDs.isEmpty,
                  let station = MusicStationOption(rawValue: key) else { return nil }
            return (station: station, count: songIDs.count)
        }
        .sorted { $0.station.rawValue < $1.station.rawValue }
    }

    // MARK: - Persistence

    private func save() {
        // Convert Set<String> to [String] for JSON encoding
        let encodable = dislikes.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(encodable) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else { return }
        dislikes = decoded.mapValues { Set($0) }
    }
}
