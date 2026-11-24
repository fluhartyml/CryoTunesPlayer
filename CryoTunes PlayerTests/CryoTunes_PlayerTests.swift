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

/// Review 044: every station's saved key is frozen as of 2026-11-24. If this fails, a case's
/// raw value was changed — that orphans listeners' dislikes, Likes playlists and Shortcuts.
/// Change `displayName` instead.
struct StationKeyTests {
    @Test func savedKeysAreFrozen() {
        let frozen: [String] = [
            "Off",
            "Ambient",
            "Chill",
            "Jazz",
            "Country",
            "Electronic",
            "New in Pop",
            "Rock Station",
            "R&B Now",
            "Hits in Spatial Audio",
            "Big Band & Swing",
            "Early Jazz & Swing",
            "Jazz Age",
            "Ragtime & Classics",
            "Top 100: USA",
            "1958",
            "1959",
            "1960",
            "1961",
            "1962",
            "1963",
            "1964",
            "1965",
            "1966",
            "1967",
            "1968",
            "1969",
            "1970",
            "1971",
            "1972",
            "1973",
            "1974",
            "1975",
            "1976",
            "1977",
            "1978",
            "1979",
            "1980",
            "1981",
            "1982",
            "1983",
            "1984",
            "1985",
            "1986",
            "1987",
            "1988",
            "1989",
            "1990",
            "1991",
            "1992",
            "1993",
            "1994",
            "1995",
            "1996",
            "1997",
            "1998",
            "1999",
            "2000",
            "2001",
            "2002",
            "2003",
            "2004",
            "2005",
            "2006",
            "2007",
            "2008",
            "2009",
            "2010",
            "2011",
            "2012",
            "2013",
            "2014",
            "2015",
            "2016",
            "2017",
            "2018",
            "2019",
            "2020",
            "2021",
            "2022",
            "2023",
            "2024",
            "2025",
            "2026",
            "Infinite Rain",
            "Forest Sounds",
            "Babbling Brook",
            "Tropical Thunderstorm",
            "Ocean Waves & Thunder",
            "Waterfall and Rain",
            "Tibetan Monks Chanting Om",
            "Tibetan Singing Bowls",
            "Singing Bowls 4 Hours",
            "Rain Sounds for Sleep",
            "Oscillating Fan",
            "Vacuum Cleaner",
            "Washing Machine",
            "Hair Dryer",
            "Pink Floyd Radio",
            "My Personal Station",
            "Discovery Station",
            "Tony Bennett Radio",
            "Daft Punk Radio",
            "Enya Radio",
            "Nova Jazzers Radio",
            "Enigma Radio",
            "Bossa Lounge Radio",
            "Relax",
            "Focus Radio",
            "Energy",
            "Feel Good",
            "Apple Music 1",
            "Apple Music Hits",
            "Apple Music Country",
            "Apple Music Chill",
            "Classic Rock Station",
            "Smooth Jazz Station",
            "Sleep",
            "Pop Station",
            "80s Hits Station",
            "Classical Station",
            "Spa Station",
            "Piano Station",
            "Dance Station",
            "Adult Rock Station",
            "Lo-Fi Station",
            "Country Hits Station",
            "Jazz Station",
            "Indie Station",
            "Acoustic Station",
            "Pure Focus",
            "Focus Frequency",
            "432 Hz Calm Breathing",
            "432 Hz Positive Shift",
            "432 Hz Light Work"
        ]
        #expect(MusicStationOption.allCases.map(\.savedKey) == frozen)
    }

    @Test func savedKeysAreUnique() {
        let keys = MusicStationOption.allCases.map(\.savedKey)
        #expect(Set(keys).count == keys.count)
    }
}
