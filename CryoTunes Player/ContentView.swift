//
//  ContentView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import SwiftUI
import MusicKit
import ShazamKit
import CryoKit

struct ContentView: View {
    @State private var playerManager = MusicPlaybackManager()
    @State private var weatherManager = CryoWeatherManager()
    @State private var dislikeManager = DislikeManager()
    @State private var playlistManager = PlaylistManager()
    @State private var showSettings = false
    @State private var showAlbumView = false
    @State private var selectedAlbum: Album?
    @State private var shazamManager = ShazamManager()
    @State private var shazamLoadingAlbum = false
    @State private var showShazamNoMatchSheet = false

    // Ice blue palette
    private let iceBlue = Color(red: 0.65, green: 0.82, blue: 0.95)
    private let iceDark = Color(red: 0.12, green: 0.18, blue: 0.28)
    private let iceGlow = Color(red: 0.45, green: 0.72, blue: 0.92)
    private let iceBorder = Color(red: 0.35, green: 0.55, blue: 0.75)
    private let iceAccent = Color(red: 0.5, green: 0.78, blue: 0.95)

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Main player UI
            VStack(spacing: 0) {
                // LCD ticker at top
                LCDTickerView(weatherManager: weatherManager)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                // Title + gear bar
                topBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                Spacer()

                // Album art — long press for album actions
                albumArtView
                    .padding(.horizontal, 32)
                    .contextMenu {
                        if let entry = ApplicationMusicPlayer.shared.queue.currentEntry,
                           case let .song(song) = entry.item {
                            Button {
                                openAlbumInApp(for: song)
                            } label: {
                                Label("Open Album", systemImage: "music.note.list")
                            }

                            Button {
                                addAlbumToLibrary(for: song)
                            } label: {
                                Label("Add Album to Library", systemImage: "plus.rectangle.on.folder")
                            }

                            Button {
                                playAlbum(for: song)
                            } label: {
                                Label("Play This Album", systemImage: "play.rectangle")
                            }

                            Button {
                                openAlbumInStore(for: song)
                            } label: {
                                Label("Open in iTunes Store", systemImage: "arrow.up.forward.app")
                            }

                            if let url = song.url {
                                ShareLink(item: url) {
                                    Label("Share Song", systemImage: "square.and.arrow.up")
                                }
                            }
                        }
                    }

                Spacer().frame(height: 20)

                // Track info
                trackInfoView

                Spacer().frame(height: 6)

                // Progress bar
                progressBar
                    .padding(.horizontal, 32)

                Spacer().frame(height: 8)

                // Sleep timer display
                timerDisplay

                Spacer().frame(height: 12)

                // Transport controls
                transportControls

                Spacer().frame(height: 20)

                // Station display
                stationDisplay

                Spacer()
            }
            .padding(.bottom, 20)
        }
        .overlay(alignment: .center) {
            if shazamLoadingAlbum {
                shazamLoadingOverlay
            } else if !playerManager.errorMessage.isEmpty {
                errorOverlay
            }
        }
        .onChange(of: shazamManager.matchedTitle) { _, newTitle in
            guard !newTitle.isEmpty else { return }
            shazamLoadingAlbum = true
            openShazamAlbum()
        }
        .onChange(of: shazamManager.noMatch) { _, newNoMatch in
            guard newNoMatch else { return }
            shazamManager.noMatch = false
            showShazamNoMatchSheet = true
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(playerManager: playerManager, dislikeManager: dislikeManager)
        }
        .sheet(isPresented: $showAlbumView) {
            if let album = selectedAlbum {
                AlbumDetailView(album: album, playlistManager: playlistManager)
            }
        }
        .sheet(isPresented: $showShazamNoMatchSheet) {
            ShazamNoMatchSheet()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            weatherManager.requestWeather()
            shazamManager.playlistManager = playlistManager
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.15),
                Color(red: 0.1, green: 0.15, blue: 0.25),
                Color(red: 0.05, green: 0.08, blue: 0.15)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Top Bar

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(version) (\(build))"
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("CryoTunes")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                    Text(appVersion)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundStyle(iceBorder.opacity(0.5))
                }
                Text("Player")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceBlue.opacity(0.6))
            }

            Spacer()

            // Shazam button
            Button {
                Task { await shazamManager.startListening() }
            } label: {
                Image(systemName: shazamManager.isListening ? "waveform" : "shazam.logo.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(shazamManager.isListening ? iceGlow : iceBlue)
                    .symbolEffect(.pulse, isActive: shazamManager.isListening)
                    .frame(width: 44, height: 44)
            }
            .padding(.trailing, 8)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(iceBlue)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Album Art

    private var albumArtView: some View {
        ZStack {
            // Bevel frame
            RoundedRectangle(cornerRadius: 8)
                .fill(iceDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                colors: [iceBorder.opacity(0.8), iceBorder.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            if let url = playerManager.currentArtworkURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(4)
                    default:
                        artPlaceholder
                    }
                }
            } else {
                artPlaceholder
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private var artPlaceholder: some View {
        if let uiImage = UIImage(named: "AppIcon") {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(4)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundStyle(iceBorder.opacity(0.4))
                Text("CryoTunes Player")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceBorder.opacity(0.4))
            }
        }
    }

    // MARK: - Track Info

    private var trackInfoView: some View {
        VStack(spacing: 4) {
            // Retro LCD-style display
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(iceBorder.opacity(0.3), lineWidth: 1)
                    )

                VStack(spacing: 2) {
                    Text(playerManager.currentSongTitle.isEmpty ? "No Track" : playerManager.currentSongTitle)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                        .lineLimit(1)
                        .shadow(color: iceGlow.opacity(0.3), radius: 2)

                    Text(playerManager.currentArtistName.isEmpty ? "---" : playerManager.currentArtistName)
                        .font(.system(size: 18, weight: .regular, design: .monospaced))
                        .foregroundStyle(iceAccent.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(height: 56)
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let elapsed = playerManager.playbackTime
        let duration = playerManager.trackDuration
        let remaining = max(0, duration - elapsed)
        let progress = duration > 0 ? elapsed / duration : 0

        return VStack(spacing: 4) {
            // Progress line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(iceBorder.opacity(0.2))
                        .frame(height: 3)

                    // Elapsed fill
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(iceAccent.opacity(0.6))
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)

            // Time labels
            HStack {
                Text(formatTime(elapsed))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceAccent.opacity(0.6))

                Spacer()

                Text("-\(formatTime(remaining)) / \(formatTime(duration))")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceAccent.opacity(0.6))
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Album Actions

    private func openAlbumInApp(for song: Song) {
        Task {
            do {
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first {
                    let detailedAlbum = try await album.with([.tracks])
                    await MainActor.run {
                        selectedAlbum = detailedAlbum
                        showAlbumView = true
                    }
                }
            } catch {
                print("Open album error: \(error)")
            }
        }
    }

    private func openShazamAlbum() {
        guard let appleMusicID = shazamManager.matchedSong?.appleMusicID else {
            presentShazamNoMatch()
            return
        }
        Task {
            do {
                let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(appleMusicID))
                let response = try await request.response()
                guard let song = response.items.first else {
                    await MainActor.run { presentShazamNoMatch() }
                    return
                }
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first {
                    let detailedAlbum = try await album.with([.tracks])
                    await MainActor.run {
                        shazamLoadingAlbum = false
                        shazamManager.matchedTitle = ""
                        shazamManager.matchedArtist = ""
                        shazamManager.addedToLibrary = false
                        selectedAlbum = detailedAlbum
                        showAlbumView = true
                    }
                } else {
                    await MainActor.run { presentShazamNoMatch() }
                }
            } catch {
                print("Shazam album error: \(error)")
                await MainActor.run { presentShazamNoMatch() }
            }
        }
    }

    private func presentShazamNoMatch() {
        shazamLoadingAlbum = false
        shazamManager.matchedTitle = ""
        shazamManager.matchedArtist = ""
        shazamManager.addedToLibrary = false
        showShazamNoMatchSheet = true
    }

    private func addAlbumToLibrary(for song: Song) {
        Task {
            do {
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first {
                    try await MusicLibrary.shared.add(album)
                    let detailedAlbum = try await album.with([.tracks])
                    await playlistManager.addAlbumPlaylist(detailedAlbum)
                }
            } catch {
                print("Add album error: \(error)")
            }
        }
    }

    private func playAlbum(for song: Song) {
        Task {
            do {
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first {
                    let detailedAlbum = try await album.with([.tracks])
                    await playlistManager.addAlbumPlaylist(detailedAlbum)
                    ApplicationMusicPlayer.shared.queue = .init(for: detailedAlbum.tracks ?? [])
                    try await ApplicationMusicPlayer.shared.play()
                }
            } catch {
                print("Play album error: \(error)")
            }
        }
    }

    private func openAlbumInStore(for song: Song) {
        Task {
            do {
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first, let url = album.url {
                    await MainActor.run {
                        UIApplication.shared.open(url)
                    }
                }
            } catch {
                print("Open in iTunes Store error: \(error)")
            }
        }
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        HStack {
            if !playerManager.sleepTimerRemaining.isEmpty {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(iceAccent.opacity(0.6))
                    .font(.system(size: 12))
                Text(playerManager.sleepTimerRemaining)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceAccent.opacity(0.6))
            }
        }
        .frame(height: 20)
    }

    // MARK: - Transport Controls

    private var transportControls: some View {
        CryoTransportControls(
            player: playerManager,
            dislikeManager: dislikeManager,
            playlistManager: playlistManager,
            tint: iceBlue,
            accent: iceAccent,
            dark: iceDark,
            border: iceBorder,
            glow: iceGlow
        )
    }

    private func retroButton(icon: String, size: CGFloat, prominent: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            iceDark.opacity(0.8),
                            Color(red: 0.08, green: 0.12, blue: 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            LinearGradient(
                                colors: [iceBorder.opacity(0.6), iceBorder.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(prominent ? iceBlue : iceAccent.opacity(0.8))
                .shadow(color: prominent ? iceGlow.opacity(0.4) : .clear, radius: 3)
        }
        .frame(width: prominent ? 64 : 52, height: prominent ? 52 : 44)
    }

    // MARK: - Station Display

    private var stationDisplay: some View {
        VStack(spacing: 4) {
            if playerManager.currentStation != .none {
                Text(playerManager.nowPlayingTitle)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceAccent.opacity(0.5))
                    .lineLimit(1)

                Text(playerManager.currentStation.rawValue)
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundStyle(iceBorder.opacity(0.5))

                Text(playerManager.currentStation.category.rawValue.uppercased())
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundStyle(iceBorder.opacity(0.3))
            }
        }
    }
    // MARK: - Shazam Overlays

    private var shazamLoadingOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "shazam.logo.fill")
                .font(.system(size: 32))
                .foregroundStyle(iceAccent)
                .symbolEffect(.pulse, options: .repeating)

            Text("Shazam match — loading album…")
                .font(.system(size: 18, design: .monospaced))
                .foregroundStyle(iceBlue)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iceDark.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(iceBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: iceGlow.opacity(0.2), radius: 10)
        .transition(.opacity)
    }

    private var errorOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(.red.opacity(0.7))

            Text(playerManager.errorMessage)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundStyle(iceBorder)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iceDark.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.red.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            playerManager.errorMessage = ""
        }
        .transition(.opacity)
    }
}

#Preview {
    ContentView()
}

struct ShazamNoMatchSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let iceBlue = Color(red: 0.65, green: 0.82, blue: 0.95)
    private let iceAccent = Color(red: 0.5, green: 0.78, blue: 0.95)
    private let iceBorder = Color(red: 0.35, green: 0.55, blue: 0.75)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image("CryoTunesIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 240, height: 240)
                        .cornerRadius(12)
                        .shadow(color: iceAccent.opacity(0.3), radius: 12)

                    Text("No Match Found")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                        .multilineTextAlignment(.center)

                    Text("Shazam couldn't identify this song.")
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundStyle(iceBlue.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.25),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .navigationTitle("Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(iceAccent)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}
