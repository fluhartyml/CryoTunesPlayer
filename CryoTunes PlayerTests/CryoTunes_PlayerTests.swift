//
//  CryoTunes_PlayerTests.swift
//  CryoTunes PlayerTests
//
//  Created by Michael Fluharty on 3/26/26.
//
//  REM: review sheet 037 (his "okay lock it" 2026-11-24): real unit tests go in FIRST,
//  before the playback fixes, so every later change has a safety net. Plain logic only —
//  nothing here needs a device, a network, or an Apple Music account.
//

import Testing
import Foundation
import CoreGraphics
@testable import CryoTunes_Player

// MARK: - Year channels (A-180): a channel plays only playlists named with its own year

struct YearMatchTests {
    @Test(arguments: [
        ("1996", "Hits of 1996", true),
        ("1996", "1996", true),
        ("1996", "Top 25: 1996 (Pop)", true),
        ("1996", "19961 Hits", false),
        ("1996", "Hits of 21996", false),
        ("2026", "Best of 2025", false),
        ("1996", "Nineties Hits", false),
        ("1996", "19961 and then 1996", true),
    ])
    func yearMatch(year: String, text: String, expected: Bool) {
        #expect(MusicPlaybackManager.names(year, in: text) == expected)
    }
}

// MARK: - Card quadrants (his 11-19 Mockup rule)

struct CardLayoutTests {
    private func layout(width: CGFloat, height: CGFloat) -> CardLayout {
        CardLayout(size: CGSize(width: width, height: height), trailingInset: 0,
                   fullWidth: width, creaseMidX: nil, creaseMidY: nil, topReserve: 0)
    }

    @Test func wideScreenHasFourQuadrants() {
        let l = layout(width: 1000, height: 800)
        #expect(l.hasQuadrants)
        let tl = l.rect(for: .topLeft), tr = l.rect(for: .topRight)
        let bl = l.rect(for: .bottomLeft), br = l.rect(for: .bottomRight)
        #expect(tl.maxX <= tr.minX)          // left | right do not overlap
        #expect(tl.maxY <= bl.minY)          // top | bottom do not overlap
        #expect(br.minX >= bl.maxX)
        for r in [tl, tr, bl, br] {          // every card stays on the screen
            #expect(r.minX >= 0 && r.minY >= 0 && r.maxX <= 1000 && r.maxY <= 800)
            #expect(r.width > 0 && r.height > 0)
        }
    }

    @Test func narrowScreenMergesLeftAndRight() {
        let l = layout(width: 400, height: 800)
        #expect(!l.hasQuadrants)
        #expect(l.rect(for: .topLeft) == l.rect(for: .topRight))
        #expect(l.rect(for: .topLeft).maxY <= l.rect(for: .bottomLeft).minY)
    }

    @Test func shortWideScreenGivesEachCardItsWholeSide() {
        let l = layout(width: 900, height: 400)   // an iPhone turned sideways
        #expect(l.hasQuadrants)
        #expect(l.rect(for: .topLeft) == l.rect(for: .bottomLeft))
    }

    @Test func quadrantLabelsAreShortForVoiceControl() {
        for q in CardQuadrant.allCases {
            #expect(q.label.split(separator: " ").count <= 3)   // his three-word rule
        }
    }
}

// MARK: - Apple Radio buckets and the hidden-station list

struct StationGroupingTests {
    @Test func everyBucketHasStations() {
        for bucket in AppleRadioBucket.allCases {
            #expect(!bucket.stations.isEmpty, "\(bucket.rawValue) is empty")
        }
    }

    @Test func hiddenStationsNeverShowInThePicker() {
        for bucket in AppleRadioBucket.allCases {
            for station in bucket.visibleStations {
                #expect(!station.isHiddenInPicker)
            }
        }
        #expect(MusicStationOption.bossaLoungeRadio.isHiddenInPicker)
    }

    @Test func stationNamesAreUnique() {
        let names = MusicStationOption.allCases.map(\.rawValue)
        #expect(Set(names).count == names.count)   // the name is also the saved key (sheet 044)
    }
}

// MARK: - Dislikes and the Previous-to-undo window

@MainActor
struct DislikeTests {
    @Test func dislikeThenUndo() {
        let manager = DislikeManager()
        let station = MusicStationOption.allCases.first { $0 != .none }!
        let song = "test-song-\(UUID().uuidString)"
        defer { manager.resetStation(station) }

        manager.dislike(songID: song, on: station)
        #expect(manager.isDisliked(songID: song, on: station))

        manager.undoLastDislike()
        #expect(!manager.isDisliked(songID: song, on: station))
        #expect(manager.lastDislike == nil)
    }

    @Test func clearUndoKeepsTheDislike() {
        let manager = DislikeManager()
        let station = MusicStationOption.allCases.first { $0 != .none }!
        let song = "test-song-\(UUID().uuidString)"
        defer { manager.resetStation(station) }

        manager.dislike(songID: song, on: station)
        manager.clearUndo()
        manager.undoLastDislike()                 // nothing left to undo
        #expect(manager.isDisliked(songID: song, on: station))
    }

    // REM: review 008/010 (2026-11-24): the skip is queue move 1, so Previous still undoes
    // REM: during the next song; move 2 (that song ending) closes the window.
    @Test func undoSurvivesTheSkipThenClosesOnTheNextSong() {
        let manager = DislikeManager()
        let station = MusicStationOption.allCases.first { $0 != .none }!
        let song = "test-song-\(UUID().uuidString)"
        defer { manager.resetStation(station) }

        manager.dislike(songID: song, on: station)
        manager.noteEntryChanged()
        #expect(manager.lastDislike != nil)
        manager.noteEntryChanged()
        #expect(manager.lastDislike == nil)
        #expect(manager.isDisliked(songID: song, on: station))
    }
}

// MARK: - Sleep timer (review 040)

struct SleepTimerTests {
    @Test func endOfSongIsOffered() {
        #expect(SleepTimerOption.allCases.contains(.endOfSong))
    }

    // Voice Control truncates long names: three words max (his rule 11-04).
    @Test func spokenNamesAreThreeWordsMax() {
        for option in SleepTimerOption.allCases {
            #expect(option.accessibilityName.split(separator: " ").count <= 3)
        }
    }
}
