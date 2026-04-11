//
//  AlbumDetailView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 4/11/26.
//
//  In-app album view — browse tracks without leaving CryoTunes.
//

import SwiftUI
import MusicKit

struct AlbumDetailView: View {
    let album: Album
    let playlistManager: PlaylistManager
    @Environment(\.dismiss) private var dismiss

    private let iceBlue = Color(red: 0.65, green: 0.82, blue: 0.95)
    private let iceDark = Color(red: 0.12, green: 0.18, blue: 0.28)
    private let iceBorder = Color(red: 0.35, green: 0.55, blue: 0.75)
    private let iceAccent = Color(red: 0.5, green: 0.78, blue: 0.95)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Album artwork
                    if let artwork = album.artwork {
                        ArtworkImage(artwork, width: 240, height: 240)
                            .cornerRadius(12)
                            .shadow(color: iceAccent.opacity(0.3), radius: 12)
                    }

                    // Album info
                    VStack(spacing: 6) {
                        Text(album.title)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(iceBlue)
                            .multilineTextAlignment(.center)

                        Text(album.artistName)
                            .font(.system(size: 18, design: .monospaced))
                            .foregroundStyle(iceBlue.opacity(0.7))

                        if let releaseDate = album.releaseDate {
                            Text(releaseDate, format: .dateTime.year())
                                .font(.system(size: 18, design: .monospaced))
                                .foregroundStyle(iceBlue.opacity(0.5))
                        }

                        if album.trackCount > 0 {
                            Text("\(album.trackCount) tracks")
                                .font(.system(size: 18, design: .monospaced))
                                .foregroundStyle(iceBlue.opacity(0.5))
                        }
                    }

                    // Action buttons
                    HStack(spacing: 16) {
                        Button {
                            playAlbum()
                        } label: {
                            Label("Play", systemImage: "play.fill")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(iceAccent.opacity(0.4))
                                .cornerRadius(8)
                        }

                        Button {
                            addToLibrary()
                        } label: {
                            Label("Add to Library", systemImage: "plus")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundStyle(iceBlue)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(iceBorder.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }

                    // Track listing
                    if let tracks = album.tracks {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                                Button {
                                    playTrack(track, fromTracks: tracks)
                                } label: {
                                    HStack(spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 18, design: .monospaced))
                                            .foregroundStyle(iceBlue.opacity(0.4))
                                            .frame(width: 30, alignment: .trailing)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(track.title)
                                                .font(.system(size: 18, design: .monospaced))
                                                .foregroundStyle(iceBlue)
                                                .lineLimit(1)

                                            if let duration = track.duration {
                                                Text(formatDuration(duration))
                                                    .font(.system(size: 14, design: .monospaced))
                                                    .foregroundStyle(iceBlue.opacity(0.4))
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                }

                                if index < tracks.count - 1 {
                                    Divider()
                                        .background(iceBorder.opacity(0.2))
                                        .padding(.leading, 54)
                                }
                            }
                        }
                        .background(iceDark.opacity(0.5))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(iceBorder.opacity(0.3), lineWidth: 1)
                        )
                    }
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

    // MARK: - Actions

    private func playAlbum() {
        Task {
            await playlistManager.addAlbumPlaylist(album)
            if let tracks = album.tracks {
                ApplicationMusicPlayer.shared.queue = .init(for: tracks)
                try? await ApplicationMusicPlayer.shared.play()
            }
            await MainActor.run { dismiss() }
        }
    }

    private func addToLibrary() {
        Task {
            try? await MusicLibrary.shared.add(album)
            await playlistManager.addAlbumPlaylist(album)
        }
    }

    private func playTrack(_ track: Track, fromTracks tracks: MusicItemCollection<Track>) {
        Task {
            ApplicationMusicPlayer.shared.queue = .init(for: tracks, startingAt: track)
            try? await ApplicationMusicPlayer.shared.play()
            await MainActor.run { dismiss() }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
