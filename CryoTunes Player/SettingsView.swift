//
//  SettingsView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import SwiftUI
import AVKit
import MusicKit
import CryoKit

struct SettingsView: View {
    @Bindable var playerManager: MusicPlaybackManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedSleepTimer") private var selectedSleepTimerRaw: Int = 0
    @State private var expandedCategories: Set<StationCategory> = []
    @State private var expandedDecades: Set<BillboardDecade> = []
    @State private var asmrExpanded = false
    @State private var myMusicExpanded = false
    @State private var playlistsExpanded = false
    @State private var albumsExpanded = false
    @State private var artistsExpanded = false
    @State private var selectedArtist: Artist?
    @State private var selectedAlbum: Album?
    @State private var libraryLoaded = false

    private let iceBlue = Color(red: 0.65, green: 0.82, blue: 0.95)
    private let iceDark = Color(red: 0.12, green: 0.18, blue: 0.28)
    private let iceBorder = Color(red: 0.35, green: 0.55, blue: 0.75)
    private let iceAccent = Color(red: 0.5, green: 0.78, blue: 0.95)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Station Picker
                    stationSection

                    // Sleep Timer
                    sleepTimerSection

                    // AirPlay
                    airPlaySection

                    // About
                    aboutSection
                }
                .padding(16)
            }
            .background(Color(red: 0.06, green: 0.09, blue: 0.16))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(iceBlue)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Station Picker

    private var stationSection: some View {
        sectionContainer(title: "Stations") {
            VStack(spacing: 0) {
                ForEach(StationCategory.allCases, id: \.self) { category in
                    if category == .billboard {
                        billboardCategoryPicker
                    } else {
                        stationCategoryPicker(category: category)
                    }
                }

                // My Music (library)
                myMusicPicker
            }
        }
    }

    private func stationCategoryPicker(category: StationCategory) -> some View {
        VStack(spacing: 0) {
            // Category header
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
                        .font(.system(size: 12))
                        .foregroundStyle(iceBorder)
                        .frame(width: 20)

                    Text(category.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)

                    Spacer()

                    if !expandedCategories.contains(category) &&
                        playerManager.currentStation.category == category {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                            .foregroundStyle(iceAccent)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }

            if expandedCategories.contains(category) {
                ForEach(MusicStationOption.stations(for: category), id: \.self) { station in
                    stationRow(station: station)
                }

                // ASMR nested reveal (only in Sound Machine)
                if category == .nature {
                    asmrSubSection
                }
            }
        }
    }

    private var asmrSubSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    asmrExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: asmrExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(iceBorder.opacity(0.7))
                        .frame(width: 20)

                    Text("ASMR")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(iceAccent)

                    Spacer()

                    if !asmrExpanded &&
                        MusicStationOption.asmrStations.contains(playerManager.currentStation) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11))
                            .foregroundStyle(iceAccent)
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

    private var billboardCategoryPicker: some View {
        VStack(spacing: 0) {
            // Billboard header
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
                        .font(.system(size: 12))
                        .foregroundStyle(iceBorder)
                        .frame(width: 20)

                    Text("Popular Hits")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)

                    Spacer()

                    if !expandedCategories.contains(.billboard) &&
                        playerManager.currentStation.category == .billboard {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                            .foregroundStyle(iceAccent)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }

            if expandedCategories.contains(.billboard) {
                // Top 100 USA at the top
                stationRow(station: .top100USA)

                // Decades
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
                        .font(.system(size: 11))
                        .foregroundStyle(iceBorder.opacity(0.7))
                        .frame(width: 20)

                    Text(decade.rawValue)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(iceAccent)

                    Spacer()

                    if !expandedDecades.contains(decade) &&
                        playerManager.currentStation.decade == decade {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11))
                            .foregroundStyle(iceAccent)
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

    private func stationRow(station: MusicStationOption, indent: Bool = false) -> some View {
        Button {
            Task {
                await playerManager.play(station: station)
            }
        } label: {
            HStack {
                Image(systemName: playerManager.currentStation == station ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(playerManager.currentStation == station ? iceAccent : iceBorder.opacity(0.5))

                Text(station.rawValue)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(playerManager.currentStation == station ? iceBlue : iceBlue.opacity(0.7))

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.leading, indent ? 48 : 28)
            .padding(.trailing, 8)
        }
    }

    // MARK: - My Music

    private var myMusicPicker: some View {
        VStack(spacing: 0) {
            // My Music header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    myMusicExpanded.toggle()
                    if myMusicExpanded && !libraryLoaded {
                        libraryLoaded = true
                        Task { await playerManager.loadLibrary() }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: myMusicExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(iceBorder)
                        .frame(width: 20)

                    Image(systemName: "music.note.house.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(iceAccent)

                    Text("My Music")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)

                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }

            if myMusicExpanded {
                // Playlists
                myMusicSubSection(
                    title: "Playlists",
                    count: playerManager.libraryPlaylists.count,
                    isExpanded: $playlistsExpanded
                ) {
                    ForEach(playerManager.libraryPlaylists, id: \.id) { playlist in
                        Button {
                            Task { await playerManager.playPlaylist(playlist) }
                        } label: {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 12))
                                    .foregroundStyle(iceBorder.opacity(0.5))

                                Text(playlist.name)
                                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                                    .foregroundStyle(iceBlue.opacity(0.7))
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.leading, 48)
                            .padding(.trailing, 8)
                        }
                    }
                }

                // Albums
                myMusicSubSection(
                    title: "Albums",
                    count: playerManager.libraryAlbums.count,
                    isExpanded: $albumsExpanded
                ) {
                    ForEach(playerManager.libraryAlbums, id: \.id) { album in
                        Button {
                            Task { await playerManager.playAlbum(album) }
                        } label: {
                            HStack {
                                Image(systemName: "square.stack")
                                    .font(.system(size: 12))
                                    .foregroundStyle(iceBorder.opacity(0.5))

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(album.title)
                                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                                        .foregroundStyle(iceBlue.opacity(0.7))
                                        .lineLimit(1)
                                    Text(album.artistName)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(iceBorder.opacity(0.5))
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

                // Artists
                myMusicSubSection(
                    title: "Artists",
                    count: playerManager.libraryArtists.count,
                    isExpanded: $artistsExpanded
                ) {
                    ForEach(playerManager.libraryArtists, id: \.id) { artist in
                        Button {
                            Task { await playerManager.loadSongs(for: artist) }
                            selectedArtist = artist
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(iceBorder.opacity(0.5))

                                Text(artist.name)
                                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                                    .foregroundStyle(iceBlue.opacity(0.7))
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

    private func myMusicSubSection<Content: View>(
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
                        .font(.system(size: 11))
                        .foregroundStyle(iceBorder.opacity(0.7))
                        .frame(width: 20)

                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(iceAccent)

                    Spacer()

                    Text("\(count)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(iceBorder.opacity(0.5))
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

    // MARK: - Sleep Timer

    private var sleepTimerSection: some View {
        sectionContainer(title: "Sleep Timer") {
            HStack(spacing: 8) {
                ForEach(SleepTimerOption.allCases, id: \.self) { option in
                    Button {
                        selectedSleepTimerRaw = option.rawValue
                        playerManager.startSleepTimer(minutes: option.rawValue)
                    } label: {
                        Text(option.displayName)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(selectedSleepTimerRaw == option.rawValue ? .black : iceBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedSleepTimerRaw == option.rawValue ? iceAccent : iceDark)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(iceBorder.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - AirPlay

    private var airPlaySection: some View {
        sectionContainer(title: "AirPlay") {
            AirPlayButton()
                .frame(height: 44)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        sectionContainer(title: "About") {
            VStack(spacing: 6) {
                HStack {
                    Text("CryoTunes Player")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                    Spacer()
                    Text("v2.1")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(iceBorder)
                }
                HStack {
                    Text("Michael Lee Fluharty")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(iceBorder.opacity(0.7))
                    Spacer()
                }
                HStack {
                    Text("Engineered with Claude by Anthropic")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(iceBorder.opacity(0.5))
                    Spacer()
                }
                Divider().overlay(iceBorder.opacity(0.2))
                Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 11))
                        Text("Weather")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(iceBorder.opacity(0.5))
                }
            }
        }
    }

    // MARK: - Section Container

    private func sectionContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(iceBorder)
                .tracking(1.5)

            VStack(spacing: 0) {
                content()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(iceBorder.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - AirPlay Button (UIKit bridge)

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = UIColor(red: 0.5, green: 0.78, blue: 0.95, alpha: 1.0)
        routePickerView.activeTintColor = UIColor(red: 0.65, green: 0.82, blue: 0.95, alpha: 1.0)
        return routePickerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
