//
//  StationGrouping.swift
//  CryoTunes Player
//
//  CryoTunes-side classification of Apple Radio stations into UI buckets.
//  CryoKit provides the flat list; this file decides how to render them.
//

import Foundation
import CryoKit

enum AppleRadioBucket: String, CaseIterable, Sendable {
    case flagship = "Flagship"
    case genre = "Genre"
    case mood = "Mood"
    case artist = "Artist"
    case terrestrial = "Terrestrial"
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
        case .sunny991, .kroq, .kiis1027, .rock955, .lite1067,
             .kEarth101, .wild949, .power1051, .q1043, .channel933,
             .lite939, .theEnd1077:
            return .terrestrial
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
}
