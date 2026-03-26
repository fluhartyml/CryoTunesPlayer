//
//  ContentView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import SwiftUI
import MusicKit

struct ContentView: View {
    @State private var playerManager = MusicPlayerManager()
    @State private var weatherManager = WeatherManager()
    // @State private var leaderSync = LeaderFollowerSync() // v1.1: CloudKit follower sync
    @State private var showSettings = false
    // Background image deferred to v1.1

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
                // Top bar
                topBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                Spacer()

                // Album art
                albumArtView
                    .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                // Track info
                trackInfoView

                Spacer().frame(height: 12)

                // LCD ticker — time, date, weather
                LCDTickerView(weatherManager: weatherManager)
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
        .sheet(isPresented: $showSettings) {
            SettingsView(playerManager: playerManager)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            weatherManager.requestWeather()
            // v1.1: CloudKit follower sync callbacks
            // leaderSync.onStationChanged = { station in
            //     Task { await playerManager.play(station: station) }
            // }
            // leaderSync.onSleepTimerChanged = { minutes in
            //     playerManager.startSleepTimer(minutes: minutes)
            // }
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

    private var topBar: some View {
        HStack {
            Text("CryoTunes")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(iceBlue)

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(iceBlue)
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

    private var artPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundStyle(iceBorder.opacity(0.4))
            Text("CryoTunes Player")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(iceBorder.opacity(0.4))
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
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                        .lineLimit(1)
                        .shadow(color: iceGlow.opacity(0.3), radius: 2)

                    Text(playerManager.currentArtistName.isEmpty ? "---" : playerManager.currentArtistName)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
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
        HStack(spacing: 32) {
            // Skip back
            Button { playerManager.skipBack() } label: {
                retroButton(icon: "backward.fill", size: 24)
            }

            // Play/Pause
            Button { playerManager.togglePlayPause() } label: {
                retroButton(
                    icon: playerManager.isPlaying ? "pause.fill" : "play.fill",
                    size: 32,
                    prominent: true
                )
            }

            // Skip forward
            Button { playerManager.skipForward() } label: {
                retroButton(icon: "forward.fill", size: 24)
            }

            // Stop
            Button { playerManager.stop() } label: {
                retroButton(icon: "stop.fill", size: 22)
            }
        }
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
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceAccent.opacity(0.5))
                    .lineLimit(1)

                Text(playerManager.currentStation.category.rawValue.uppercased())
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(iceBorder.opacity(0.4))
            }
        }
    }
}

#Preview {
    ContentView()
}
