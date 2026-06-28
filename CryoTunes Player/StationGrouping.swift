//
//  StationGrouping.swift
//  CryoTunes Player
//
//  CryoTunes-side classification of Apple Radio stations into UI buckets.
//  CryoKit provides the flat list; this file decides how to render them.
//

import Foundation

enum AppleRadioBucket: String, CaseIterable, Sendable {
    case flagship = "Flagship"
    case genre = "Genre"
    case mood = "Mood"
    case artist = "Artist"
    case personal = "Personal"
}

extension MusicStationOption {
    /// Apple Radio sub-bucket for UI rendering. nil for non-Apple-Radio stations.
    var appleRadioBucket: AppleRadioBucket? {
        switch self {
        case .appleMusic1, .appleMusicHits, .appleMusicCountry, .appleMusicChill:
            return .flagship
        case .popStation, .classicRockStation, .adultRockStation,
             .smoothJazzStation, .jazzStation, .countryHitsStation,
             .classicalStation, .danceStation, .lofiStation,
             .indieStation, .acousticStation, .eightiesHits:
            return .genre
        case .sleepStation, .spaStation, .pianoStation,
             .relaxRadio, .focusRadio, .energyRadio, .feelGoodRadio,
             .bossaLoungeRadio:
            return .mood
        case .pinkFloydRadio, .tonyBennettRadio, .daftPunkRadio,
             .enyaRadio, .novaJazzersRadio, .enigmaRadio:
            return .artist
        case .personalStation, .discoveryStation:
            return .personal
        default:
            return nil
        }
    }
}

extension AppleRadioBucket {
    /// All stations in this bucket, in catalog declaration order.
    var stations: [MusicStationOption] {
        MusicStationOption.allCases.filter { $0.appleRadioBucket == self }
    }

    /// Stations in this bucket that aren't on the hidden-in-picker list.
    var visibleStations: [MusicStationOption] {
        stations.filter { !$0.isHiddenInPicker }
    }
}

extension MusicStationOption {
    /// Stations that don't reliably play via MusicKit's third-party API and
    /// shouldn't surface in the picker UI. Data stays in CryoKit (catalog is
    /// canonical); presentation layer filters here.
    ///
    /// Verified silently failing on real-device test 2026-05-01:
    /// - Bossa Lounge Radio: ra.882820073 returns no station, name search dead
    /// - My Personal Station: dynamic /v1/me/stations API returns empty
    /// - Tibetan Singing Bowls: "satiro" album rotated out of Apple Music
    static let hiddenInPicker: Set<MusicStationOption> = [
        .bossaLoungeRadio,
        .personalStation,
        .tibetanSingingBowls
    ]

    var isHiddenInPicker: Bool {
        Self.hiddenInPicker.contains(self)
    }
}
