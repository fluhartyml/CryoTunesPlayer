//
//  CryoStationPicker.swift
//  CryoTunes Player
//
//  Local copy — CryoKit serves data only, apps own their views.
//

import SwiftUI
import MusicKit
import CryoKit

struct CryoStationPicker: View {
    @Bindable var player: MusicPlaybackManager
    var stationFailureMonitor: StationFailureMonitor
    let tint: Color
    let accent: Color
    let border: Color

    @State private var expandedCategories: Set<StationCategory> = []
    @State private var expandedDecades: Set<BillboardDecade> = []
    @State private var expandedBuckets: Set<AppleRadioBucket> = []
    @State private var asmrExpanded = false
    @State private var myMusicExpanded = false
    @State private var playlistsExpanded = false
    @State private var albumsExpanded = false
    @State private var artistsExpanded = false
    @State private var libraryLoaded = false
    @State private var expandedPlaylistID: MusicItemID?
    @State private var revealedSongs: [Song] = []
    @State private var playlistTrackCounts: [MusicItemID: Int] = [:]
    // Native Apple Music picker (iOS 27+). Gated at the call site.
    @State private var showMusicPicker = false
    @State private var pickedSongs: [Song] = []   // picker is multi-select; we play the first

    var body: some View {
        VStack(spacing: 0) {
            ForEach(StationCategory.allCases, id: \.self) { category in
                if category == .billboard {
                    billboardCategoryPicker
                } else if category == .appleRadio {
                    appleRadioCategoryPicker
                } else {
                    stationCategoryPicker(category: category)
                }
            }

            myMusicPicker
        }
    }

    // MARK: - Station Category

    private func stationCategoryPicker(category: StationCategory) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                        .foregroundStyle(border)
                        .frame(width: 20)

                    Text(category.rawValue)
                        .foregroundStyle(tint)

                    Spacer()

                    if !expandedCategories.contains(category) &&
                        player.currentStation.category == category {
                        Image(systemName: "checkmark")
                            .foregroundStyle(accent)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }

            if expandedCategories.contains(category) {
                ForEach(MusicStationOption.stations(for: category).filter {
                    $0 != .personalStation && $0 != .discoveryStation && !$0.isHiddenInPicker
                }, id: \.self) { station in
                    stationRow(station: station)
                }

                if category == .nature {
                    asmrSubSection
                }
            }
        }
    }

    // MARK: - ASMR

    private var asmrSubSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    asmrExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: asmrExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(border.opacity(0.7))
                        .frame(width: 20)

                    Text("ASMR")
                        .foregroundStyle(accent)

                    Spacer()

                    if !asmrExpanded &&
                        MusicStationOption.asmrStations.contains(player.currentStation) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(accent)
                    }
                }
                .padding(.vertical, 8)
                .padding(.leading, 28)
                .padding(.trailing, 8)
            }

            if asmrExpanded {
                ForEach(MusicStationOption.asmrStations, id: \.self) { station in
                    stationRow(station: station, indent: true)
                }
            }
        }
    }

    // MARK: - Apple Radio (bucketed)

    private var appleRadioCategoryPicker: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedCategories.contains(.appleRadio) {
                        expandedCategories.remove(.appleRadio)
                    } else {
                        expandedCategories.insert(.appleRadio)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedCategories.contains(.appleRadio) ? "chevron.down" : "chevron.right")
                        .foregroundStyle(border)
                        .frame(width: 20)

                    Text(StationCategory.appleRadio.rawValue)
                        .foregroundStyle(tint)

                    Spacer()

                    if !expandedCategories.contains(.appleRadio) &&
                        player.currentStation.category == .appleRadio {
                        Image(systemName: "checkmark")
                            .foregroundStyle(accent)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }

            if expandedCategories.contains(.appleRadio) {
                ForEach(AppleRadioBucket.allCases.filter { !$0.visibleStations.isEmpty }, id: \.self) { bucket in
                    bucketPicker(bucket: bucket)
                }
            }
        }
    }

    private func bucketPicker(bucket: AppleRadioBucket) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedBuckets.contains(bucket) {
                        expandedBuckets.remove(bucket)
                    } else {
                        expandedBuckets.insert(bucket)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedBuckets.contains(bucket) ? "chevron.down" : "chevron.right")
                        .foregroundStyle(border.opacity(0.7))
                        .frame(width: 20)

                    Text(bucket.rawValue)
                        .foregroundStyle(accent)

                    Spacer()

                    if !expandedBuckets.contains(bucket) &&
                        player.currentStation.appleRadioBucket == bucket {
                        Image(systemName: "checkmark")
                            .foregroundStyle(accent)
                    }
                }
                .padding(.vertical, 8)
                .padding(.leading, 28)
                .padding(.trailing, 8)
            }

            if expandedBuckets.contains(bucket) {
                ForEach(bucket.visibleStations, id: \.self) { station in
                    stationRow(station: station, indent: true)
                }
            }
        }
    }

    // MARK: - Billboard / Popular Hits

    private var billboardCategoryPicker: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedCategories.contains(.billboard) {
                        expandedCategories.remove(.billboard)
                    } else {
                        expandedCategories.insert(.billboard)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedCategories.contains(.billboard) ? "chevron.down" : "chevron.right")
                        .foregroundStyle(border)
                        .frame(width: 20)

                    Text("Popular Hits")
                        .foregroundStyle(tint)

                    Spacer()

                    if !expandedCategories.contains(.billboard) &&
                        player.currentStation.category == .billboard {
                        Image(systemName: "checkmark")
                            .foregroundStyle(accent)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }

            if expandedCategories.contains(.billboard) {
                stationRow(station: .top100USA)

                ForEach(BillboardDecade.allCases, id: \.self) { decade in
                    decadePicker(decade: decade)
                }
            }
        }
    }

    private func decadePicker(decade: BillboardDecade) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedDecades.contains(decade) {
                        expandedDecades.remove(decade)
                    } else {
                        expandedDecades.insert(decade)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedDecades.contains(decade) ? "chevron.down" : "chevron.right")
                        .foregroundStyle(border.opacity(0.7))
                        .frame(width: 20)

                    Text(decade.rawValue)
                        .foregroundStyle(accent)

                    Spacer()

                    if !expandedDecades.contains(decade) &&
                        player.currentStation.decade == decade {
                        Image(systemName: "checkmark")
                            .foregroundStyle(accent)
                    }
                }
                .padding(.vertical, 8)
                .padding(.leading, 28)
                .padding(.trailing, 8)
            }

            if expandedDecades.contains(decade) {
                ForEach(MusicStationOption.stations(for: decade), id: \.self) { station in
                    stationRow(station: station, indent: true)
                }
            }
        }
    }

    // MARK: - Station Row

    private func stationRow(station: MusicStationOption, indent: Bool = false) -> some View {
        Button {
            Task {
                await stationFailureMonitor.monitorPlay(station: station, player: player)
            }
        } label: {
            HStack {
                Image(systemName: player.currentStation == station ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(player.currentStation == station ? accent : border.opacity(0.5))

                Text(station.rawValue)
                    .foregroundStyle(player.currentStation == station ? tint : tint.opacity(0.7))

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.leading, indent ? 48 : 28)
            .padding(.trailing, 8)
        }
    }

    // MARK: - My Music

    // Native Apple Music picker — full catalog + library in one Apple-provided
    // sheet. iOS 27 only; on iOS 26 this row is hidden and My Music remains the
    // path. No subscription required (library-only without one, +catalog with).
    @available(iOS 27.0, *)
    private var searchAppleMusicButton: some View {
        Button {
            showMusicPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(accent)
                    .frame(width: 20)

                Text("Search Apple Music")
                    .foregroundStyle(tint)

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.leading, 28)
            .padding(.trailing, 8)
        }
        .musicPicker(isPresented: $showMusicPicker, selection: $pickedSongs)
        .onChange(of: showMusicPicker) { _, isShowing in
            // Play the picked song only after the picker dismisses, so the picker's
            // own preview-playback teardown can't stop us. The picker is multi-select
            // (tap + to add); CryoTunes plays the first chosen song.
            guard !isShowing, let song = pickedSongs.first else { return }
            pickedSongs = []
            Task { await player.playSong(song) }
        }
    }

    private var myMusicPicker: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    myMusicExpanded.toggle()
                    if myMusicExpanded && !libraryLoaded {
                        libraryLoaded = true
                        Task { await player.loadLibrary() }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: myMusicExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(border)
                        .frame(width: 20)

                    Image(systemName: "music.note.house.fill")
                        .foregroundStyle(accent)

                    Text("My Music")
                        .foregroundStyle(tint)

                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }

            if myMusicExpanded {
                if #available(iOS 27.0, *) {
                    searchAppleMusicButton
                }

                librarySubSection(
                    title: "Playlists",
                    count: player.libraryPlaylists.count,
                    isExpanded: $playlistsExpanded
                ) {
                    ForEach(player.libraryPlaylists, id: \.id) { playlist in
                        playlistRevealRow(playlist: playlist)
                    }
                    .onAppear { loadAllPlaylistCounts() }
                }

                librarySubSection(
                    title: "Albums",
                    count: player.libraryAlbums.count,
                    isExpanded: $albumsExpanded
                ) {
                    ForEach(player.libraryAlbums, id: \.id) { album in
                        Button {
                            Task { await player.playAlbum(album) }
                        } label: {
                            HStack {
                                Image(systemName: "square.stack")
                                    .foregroundStyle(border.opacity(0.5))

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(album.title)
                                        .foregroundStyle(tint.opacity(0.7))
                                        .lineLimit(1)
                                    Text(album.artistName)
                                        .foregroundStyle(border.opacity(0.5))
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.leading, 48)
                            .padding(.trailing, 8)
                        }
                    }
                }

                librarySubSection(
                    title: "Artists",
                    count: player.libraryArtists.count,
                    isExpanded: $artistsExpanded
                ) {
                    ForEach(player.libraryArtists, id: \.id) { artist in
                        Button {
                            Task { await player.loadSongs(for: artist) }
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(border.opacity(0.5))

                                Text(artist.name)
                                    .foregroundStyle(tint.opacity(0.7))
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.leading, 48)
                            .padding(.trailing, 8)
                        }
                    }
                }
            }
        }
    }

    private func librarySubSection<Content: View>(
        title: String,
        count: Int,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                        .foregroundStyle(border.opacity(0.7))
                        .frame(width: 20)

                    Text(title)
                        .foregroundStyle(accent)

                    Spacer()

                    Text("\(count)")
                        .foregroundStyle(border.opacity(0.5))
                }
                .padding(.vertical, 8)
                .padding(.leading, 28)
                .padding(.trailing, 8)
            }

            if isExpanded.wrappedValue {
                content()
            }
        }
    }

    // MARK: - Playlist Track Count Loader

    private func loadAllPlaylistCounts() {
        for playlist in player.libraryPlaylists {
            guard playlistTrackCounts[playlist.id] == nil else { continue }
            Task {
                let detailed = try? await playlist.with([.tracks])
                let count = detailed?.tracks?.count ?? 0
                await MainActor.run {
                    playlistTrackCounts[playlist.id] = count
                }
            }
        }
    }

    // MARK: - Playlist Reveal Row

    private func playlistRevealRow(playlist: Playlist) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedPlaylistID == playlist.id {
                        expandedPlaylistID = nil
                        revealedSongs = []
                    } else {
                        expandedPlaylistID = playlist.id
                        Task {
                            let detailed = try? await playlist.with([.tracks])
                            let tracks = detailed?.tracks ?? []
                            revealedSongs = tracks.compactMap { track in
                                if case let .song(song) = track { return song }
                                return nil
                            }
                            playlistTrackCounts[playlist.id] = revealedSongs.count
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedPlaylistID == playlist.id ? "chevron.down" : "music.note.list")
                        .foregroundStyle(border.opacity(0.5))

                    Text(playlist.name)
                        .foregroundStyle(tint.opacity(0.7))
                        .lineLimit(1)

                    Spacer()

                    if expandedPlaylistID == playlist.id {
                        Text("\(revealedSongs.count) tracks")
                            .foregroundStyle(border.opacity(0.6))
                    } else if let count = playlistTrackCounts[playlist.id] {
                        Text("\(count)")
                            .foregroundStyle(border.opacity(0.5))
                    }
                }
                .padding(.vertical, 6)
                .padding(.leading, 48)
                .padding(.trailing, 8)
            }

            if expandedPlaylistID == playlist.id {
                Button {
                    Task { await player.playPlaylist(playlist) }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                            .foregroundStyle(accent.opacity(0.8))

                        Text("Play All (\(revealedSongs.count) tracks)")
                            .foregroundStyle(accent.opacity(0.8))

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.leading, 62)
                    .padding(.trailing, 8)
                }

                ForEach(revealedSongs, id: \.id) { song in
                    Button {
                        Task { await player.playSong(song) }
                    } label: {
                        HStack {
                            Text(song.title)
                                .foregroundStyle(tint.opacity(0.7))
                                .lineLimit(1)

                            Spacer()

                            Text(song.artistName)
                                .foregroundStyle(border.opacity(0.6))
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 62)
                        .padding(.trailing, 8)
                    }
                }
            }
        }
    }
}
