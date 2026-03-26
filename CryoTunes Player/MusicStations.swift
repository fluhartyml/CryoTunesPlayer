//
//  MusicStations.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import Foundation

enum StationCategory: String, CaseIterable {
    case music = "Music"
    case billboard = "Popular Hits"
    case nature = "Nature Sounds"
    case focus = "Focus"
}

enum BillboardDecade: String, CaseIterable {
    case d1950s = "1950s"
    case d1960s = "1960s"
    case d1970s = "1970s"
    case d1980s = "1980s"
    case d1990s = "1990s"
    case d2000s = "2000s"
    case d2010s = "2010s"
    case d2020s = "2020s"

    static func decades(for category: StationCategory) -> [BillboardDecade] {
        category == .billboard ? allCases : []
    }
}

enum StationSearchType {
    case stationFirst
    case stationOnly
    case playlistFirst
    case albumFirst
}

enum SleepTimerOption: Int, CaseIterable {
    case off = 0
    case thirtyMin = 30
    case sixtyMin = 60
    case twoHours = 120
    case fourHours = 240

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .thirtyMin: return "30m"
        case .sixtyMin: return "1h"
        case .twoHours: return "2h"
        case .fourHours: return "4h"
        }
    }
}

enum MusicStationOption: String, CaseIterable {
    // Music stations
    case none = "Off"
    case ambient = "Ambient"
    case chillout = "Chill"
    case jazz = "Jazz"
    case country = "Country"
    case electronic = "Electronic"
    case newInPop = "New in Pop"
    case rockStation = "Rock Station"
    case rAndBNow = "R&B Now"
    case spatialAudio = "Hits in Spatial Audio"
    case bigBand = "Big Band & Swing"
    case earlyJazz = "Early Jazz & Swing"
    case jazzAge = "Jazz Age"
    case ragtime = "Ragtime & Classics"

    // Popular Hits
    case top100USA = "Top 100: USA"
    case billboard1958 = "1958"
    case billboard1959 = "1959"
    case billboard1960 = "1960"
    case billboard1961 = "1961"
    case billboard1962 = "1962"
    case billboard1963 = "1963"
    case billboard1964 = "1964"
    case billboard1965 = "1965"
    case billboard1966 = "1966"
    case billboard1967 = "1967"
    case billboard1968 = "1968"
    case billboard1969 = "1969"
    case billboard1970 = "1970"
    case billboard1971 = "1971"
    case billboard1972 = "1972"
    case billboard1973 = "1973"
    case billboard1974 = "1974"
    case billboard1975 = "1975"
    case billboard1976 = "1976"
    case billboard1977 = "1977"
    case billboard1978 = "1978"
    case billboard1979 = "1979"
    case billboard1980 = "1980"
    case billboard1981 = "1981"
    case billboard1982 = "1982"
    case billboard1983 = "1983"
    case billboard1984 = "1984"
    case billboard1985 = "1985"
    case billboard1986 = "1986"
    case billboard1987 = "1987"
    case billboard1988 = "1988"
    case billboard1989 = "1989"
    case billboard1990 = "1990"
    case billboard1991 = "1991"
    case billboard1992 = "1992"
    case billboard1993 = "1993"
    case billboard1994 = "1994"
    case billboard1995 = "1995"
    case billboard1996 = "1996"
    case billboard1997 = "1997"
    case billboard1998 = "1998"
    case billboard1999 = "1999"
    case billboard2000 = "2000"
    case billboard2001 = "2001"
    case billboard2002 = "2002"
    case billboard2003 = "2003"
    case billboard2004 = "2004"
    case billboard2005 = "2005"
    case billboard2006 = "2006"
    case billboard2007 = "2007"
    case billboard2008 = "2008"
    case billboard2009 = "2009"
    case billboard2010 = "2010"
    case billboard2011 = "2011"
    case billboard2012 = "2012"
    case billboard2013 = "2013"
    case billboard2014 = "2014"
    case billboard2015 = "2015"
    case billboard2016 = "2016"
    case billboard2017 = "2017"
    case billboard2018 = "2018"
    case billboard2019 = "2019"
    case billboard2020 = "2020"
    case billboard2021 = "2021"
    case billboard2022 = "2022"
    case billboard2023 = "2023"
    case billboard2024 = "2024"
    case billboard2025 = "2025"

    // Nature sounds
    case infiniteRain = "Infinite Rain"
    case forestSounds = "Forest Sounds"
    case babblingBrook = "Babbling Brook"
    case tropicalThunderstorm = "Tropical Thunderstorm"
    case oceanWavesThunder = "Ocean Waves & Thunder"
    case waterfallAndRain = "Waterfall and Rain"
    case tibetanMonksOm = "Tibetan Monks Chanting Om"
    case tibetanSingingBowls = "Tibetan Singing Bowls"
    case tibetanBowls4Hr = "Singing Bowls 4 Hours"
    case rainSoundsForSleep = "Rain Sounds for Sleep"

    // Focus
    case pureFocus = "Pure Focus"
    case focusFrequency = "Focus Frequency"
    case calmBreathing = "432 Hz Calm Breathing"
    case positiveShift = "432 Hz Positive Shift"
    case lightWork = "432 Hz Light Work"

    var category: StationCategory {
        switch self {
        case .none, .ambient, .chillout, .jazz, .country, .electronic,
             .newInPop, .rockStation, .rAndBNow, .spatialAudio,
             .bigBand, .earlyJazz, .jazzAge, .ragtime:
            return .music
        case .top100USA,
             .billboard1958, .billboard1959,
             .billboard1960, .billboard1961, .billboard1962, .billboard1963, .billboard1964,
             .billboard1965, .billboard1966, .billboard1967, .billboard1968, .billboard1969,
             .billboard1970, .billboard1971, .billboard1972, .billboard1973, .billboard1974,
             .billboard1975, .billboard1976, .billboard1977, .billboard1978, .billboard1979,
             .billboard1980, .billboard1981, .billboard1982, .billboard1983, .billboard1984,
             .billboard1985, .billboard1986, .billboard1987, .billboard1988, .billboard1989,
             .billboard1990, .billboard1991, .billboard1992, .billboard1993, .billboard1994,
             .billboard1995, .billboard1996, .billboard1997, .billboard1998, .billboard1999,
             .billboard2000, .billboard2001, .billboard2002, .billboard2003, .billboard2004,
             .billboard2005, .billboard2006, .billboard2007, .billboard2008, .billboard2009,
             .billboard2010, .billboard2011, .billboard2012, .billboard2013, .billboard2014,
             .billboard2015, .billboard2016, .billboard2017, .billboard2018, .billboard2019,
             .billboard2020, .billboard2021, .billboard2022, .billboard2023, .billboard2024,
             .billboard2025:
            return .billboard
        case .infiniteRain, .forestSounds, .babblingBrook, .tropicalThunderstorm,
             .oceanWavesThunder, .waterfallAndRain, .tibetanMonksOm,
             .tibetanSingingBowls, .tibetanBowls4Hr, .rainSoundsForSleep:
            return .nature
        case .pureFocus, .focusFrequency, .calmBreathing, .positiveShift, .lightWork:
            return .focus
        }
    }

    var searchTerm: String {
        switch self {
        case .none: return ""
        case .ambient: return "ambient relaxation"
        case .chillout: return "chill vibes"
        case .jazz: return "jazz chill"
        case .country: return "country hits"
        case .electronic: return "pure electronic"
        case .newInPop: return "new in pop"
        case .rockStation: return "rock station"
        case .rAndBNow: return "R&B now"
        case .spatialAudio: return "hits in spatial audio"
        case .bigBand: return "big band swing"
        case .earlyJazz: return "early jazz swing"
        case .jazzAge: return "roaring twenties jazz"
        case .ragtime: return "ragtime classics"
        case .top100USA: return "top 100 usa"
        case .billboard1958: return "pop hits 1958"
        case .billboard1959: return "pop hits 1959"
        case .billboard1960: return "pop hits 1960"
        case .billboard1961: return "pop hits 1961"
        case .billboard1962: return "pop hits 1962"
        case .billboard1963: return "pop hits 1963"
        case .billboard1964: return "pop hits 1964"
        case .billboard1965: return "pop hits 1965"
        case .billboard1966: return "pop hits 1966"
        case .billboard1967: return "pop hits 1967"
        case .billboard1968: return "pop hits 1968"
        case .billboard1969: return "pop hits 1969"
        case .billboard1970: return "pop hits 1970"
        case .billboard1971: return "pop hits 1971"
        case .billboard1972: return "pop hits 1972"
        case .billboard1973: return "pop hits 1973"
        case .billboard1974: return "pop hits 1974"
        case .billboard1975: return "pop hits 1975"
        case .billboard1976: return "pop hits 1976"
        case .billboard1977: return "pop hits 1977"
        case .billboard1978: return "pop hits 1978"
        case .billboard1979: return "pop hits 1979"
        case .billboard1980: return "pop hits 1980"
        case .billboard1981: return "pop hits 1981"
        case .billboard1982: return "pop hits 1982"
        case .billboard1983: return "pop hits 1983"
        case .billboard1984: return "pop hits 1984"
        case .billboard1985: return "pop hits 1985"
        case .billboard1986: return "pop hits 1986"
        case .billboard1987: return "pop hits 1987"
        case .billboard1988: return "pop hits 1988"
        case .billboard1989: return "pop hits 1989"
        case .billboard1990: return "pop hits 1990"
        case .billboard1991: return "pop hits 1991"
        case .billboard1992: return "pop hits 1992"
        case .billboard1993: return "pop hits 1993"
        case .billboard1994: return "pop hits 1994"
        case .billboard1995: return "pop hits 1995"
        case .billboard1996: return "pop hits 1996"
        case .billboard1997: return "pop hits 1997"
        case .billboard1998: return "pop hits 1998"
        case .billboard1999: return "pop hits 1999"
        case .billboard2000: return "pop hits 2000"
        case .billboard2001: return "pop hits 2001"
        case .billboard2002: return "pop hits 2002"
        case .billboard2003: return "pop hits 2003"
        case .billboard2004: return "pop hits 2004"
        case .billboard2005: return "pop hits 2005"
        case .billboard2006: return "pop hits 2006"
        case .billboard2007: return "pop hits 2007"
        case .billboard2008: return "pop hits 2008"
        case .billboard2009: return "pop hits 2009"
        case .billboard2010: return "pop hits 2010"
        case .billboard2011: return "pop hits 2011"
        case .billboard2012: return "pop hits 2012"
        case .billboard2013: return "pop hits 2013"
        case .billboard2014: return "pop hits 2014"
        case .billboard2015: return "pop hits 2015"
        case .billboard2016: return "pop hits 2016"
        case .billboard2017: return "pop hits 2017"
        case .billboard2018: return "pop hits 2018"
        case .billboard2019: return "pop hits 2019"
        case .billboard2020: return "pop hits 2020"
        case .billboard2021: return "pop hits 2021"
        case .billboard2022: return "pop hits 2022"
        case .billboard2023: return "pop hits 2023"
        case .billboard2024: return "pop hits 2024"
        case .billboard2025: return "pop hits 2025"
        case .infiniteRain: return "infinite rain"
        case .forestSounds: return "forest sounds apple music wellbeing"
        case .babblingBrook: return "babbling brook nature sounds nature sound collection"
        case .tropicalThunderstorm: return "a majestic tropical thunderstorm"
        case .oceanWavesThunder: return "ocean waves gentle thunder and rain"
        case .waterfallAndRain: return "healing sounds of nature waterfall and rain"
        case .tibetanMonksOm: return "tibetan monks chanting om for deep meditation"
        case .tibetanSingingBowls: return "tibetan singing bowls satiro"
        case .tibetanBowls4Hr: return "tibetan singing bowls 4 hours for relaxation"
        case .rainSoundsForSleep: return "rain sounds for sleep silent chills"
        case .pureFocus: return "pure focus"
        case .focusFrequency: return "focus frequency increase concentration memory"
        case .calmBreathing: return "deep meditation binaural beats vol 9 lightseeds"
        case .positiveShift: return "deep meditation binaural beats vol 9 lightseeds"
        case .lightWork: return "deep meditation binaural beats vol 9 lightseeds"
        }
    }

    var searchType: StationSearchType {
        switch self {
        case .rockStation:
            return .stationOnly
        case .infiniteRain, .forestSounds, .newInPop, .rAndBNow, .spatialAudio,
             .pureFocus, .rainSoundsForSleep,
             .top100USA,
             .billboard1958, .billboard1959,
             .billboard1960, .billboard1961, .billboard1962, .billboard1963, .billboard1964,
             .billboard1965, .billboard1966, .billboard1967, .billboard1968, .billboard1969,
             .billboard1970, .billboard1971, .billboard1972, .billboard1973, .billboard1974,
             .billboard1975, .billboard1976, .billboard1977, .billboard1978, .billboard1979,
             .billboard1980, .billboard1981, .billboard1982, .billboard1983, .billboard1984,
             .billboard1985, .billboard1986, .billboard1987, .billboard1988, .billboard1989,
             .billboard1990, .billboard1991, .billboard1992, .billboard1993, .billboard1994,
             .billboard1995, .billboard1996, .billboard1997, .billboard1998, .billboard1999,
             .billboard2000, .billboard2001, .billboard2002, .billboard2003, .billboard2004,
             .billboard2005, .billboard2006, .billboard2007, .billboard2008, .billboard2009,
             .billboard2010, .billboard2011, .billboard2012, .billboard2013, .billboard2014,
             .billboard2015, .billboard2016, .billboard2017, .billboard2018, .billboard2019,
             .billboard2020, .billboard2021, .billboard2022, .billboard2023, .billboard2024,
             .billboard2025:
            return .playlistFirst
        case .babblingBrook, .tropicalThunderstorm, .oceanWavesThunder,
             .waterfallAndRain, .tibetanMonksOm, .tibetanSingingBowls,
             .tibetanBowls4Hr, .focusFrequency, .calmBreathing, .positiveShift, .lightWork:
            return .albumFirst
        default:
            return .stationFirst
        }
    }

    var decade: BillboardDecade? {
        switch self {
        case .billboard1958, .billboard1959: return .d1950s
        case .billboard1960, .billboard1961, .billboard1962, .billboard1963, .billboard1964,
             .billboard1965, .billboard1966, .billboard1967, .billboard1968, .billboard1969: return .d1960s
        case .billboard1970, .billboard1971, .billboard1972, .billboard1973, .billboard1974,
             .billboard1975, .billboard1976, .billboard1977, .billboard1978, .billboard1979: return .d1970s
        case .billboard1980, .billboard1981, .billboard1982, .billboard1983, .billboard1984,
             .billboard1985, .billboard1986, .billboard1987, .billboard1988, .billboard1989: return .d1980s
        case .billboard1990, .billboard1991, .billboard1992, .billboard1993, .billboard1994,
             .billboard1995, .billboard1996, .billboard1997, .billboard1998, .billboard1999: return .d1990s
        case .billboard2000, .billboard2001, .billboard2002, .billboard2003, .billboard2004,
             .billboard2005, .billboard2006, .billboard2007, .billboard2008, .billboard2009: return .d2000s
        case .billboard2010, .billboard2011, .billboard2012, .billboard2013, .billboard2014,
             .billboard2015, .billboard2016, .billboard2017, .billboard2018, .billboard2019: return .d2010s
        case .billboard2020, .billboard2021, .billboard2022, .billboard2023, .billboard2024,
             .billboard2025: return .d2020s
        default: return nil
        }
    }

    var shouldRepeat: Bool {
        category == .nature || category == .focus
    }

    static func stations(for category: StationCategory) -> [MusicStationOption] {
        allCases.filter { $0.category == category && $0 != .none }
    }

    static func stations(for decade: BillboardDecade) -> [MusicStationOption] {
        allCases.filter { $0.decade == decade }
    }
}
