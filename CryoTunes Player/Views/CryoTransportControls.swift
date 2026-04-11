//
//  CryoTransportControls.swift
//  CryoTunes Player
//
//  Local copy — CryoKit serves data only, apps own their views.
//

import SwiftUI
import MusicKit
import CryoKit

struct CryoTransportControls: View {
    @Bindable var player: MusicPlaybackManager
    var dislikeManager: DislikeManager
    var playlistManager: PlaylistManager
    let tint: Color
    let accent: Color
    let dark: Color
    let border: Color
    let glow: Color
    @State private var showShareSheet = false
    @State private var ratingState: RatingState = .none

    enum RatingState { case none, loved, disliked }

    var body: some View {
        VStack(spacing: 12) {
            // Row 1: Transport
            HStack(spacing: 32) {
                Button { skipBackWithUndo() } label: {
                    transportButton(icon: "backward.end.fill", size: 24)
                }

                Button { player.togglePlayPause() } label: {
                    transportButton(
                        icon: player.isPlaying ? "pause.fill" : "play.fill",
                        size: 32,
                        prominent: true
                    )
                }

                Button { skipForwardWithDislike() } label: {
                    transportButton(icon: "forward.end.fill", size: 24)
                }

                Button { player.stop() } label: {
                    transportButton(icon: "stop.fill", size: 22)
                }
            }

            // Row 2: Shuffle & Repeat
            HStack(spacing: 16) {
                Button { player.toggleShuffle() } label: {
                    modeButton(
                        icon: "shuffle",
                        label: "Shuffle",
                        isActive: player.isShuffleEnabled
                    )
                }
                .frame(maxWidth: .infinity)

                Button {
                    player.repeatMode = player.repeatMode == .all ? .none : .all
                } label: {
                    modeButton(
                        icon: "repeat",
                        label: "All",
                        isActive: player.repeatMode == .all
                    )
                }
                .frame(maxWidth: .infinity)

                Button {
                    player.repeatMode = player.repeatMode == .one ? .none : .one
                } label: {
                    modeButton(
                        icon: "repeat.1",
                        label: "One",
                        isActive: player.repeatMode == .one
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)

            // Row 3: Thumbs Up, Thumbs Down, Share
            HStack(spacing: 16) {
                Button { thumbsUp() } label: {
                    modeButton(
                        icon: "hand.thumbsup.fill",
                        label: "Like",
                        isActive: ratingState == .loved
                    )
                }
                .frame(maxWidth: .infinity)

                Button { thumbsDown() } label: {
                    modeButton(
                        icon: "hand.thumbsdown.fill",
                        label: "Skip",
                        isActive: ratingState == .disliked
                    )
                }
                .frame(maxWidth: .infinity)

                Button { showShareSheet = true } label: {
                    modeButton(
                        icon: "square.and.arrow.up",
                        label: "Share",
                        isActive: false
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)
            .sheet(isPresented: $showShareSheet) {
                if let url = currentSongShareURL {
                    ActivityView(activityItems: [url])
                }
            }
        }
        .onChange(of: player.currentSongTitle) { _, _ in
            ratingState = .none
            autoSkipIfDisliked()
        }
    }

    // MARK: - Rating & Share

    private func thumbsUp() {
        Task {
            guard let entry = ApplicationMusicPlayer.shared.queue.currentEntry,
                  case let .song(song) = entry.item else { return }
            do {
                try await MusicLibrary.shared.add(song)
                ratingState = .loved
                // Add to per-station playlist
                if player.currentStation != .none {
                    await playlistManager.addToStationPlaylist(song, station: player.currentStation)
                }
            } catch {}
        }
    }

    private func thumbsDown() {
        recordDislikeAndSkip()
    }

    /// Skip forward — just advances the track, no dislike
    private func skipForwardWithDislike() {
        player.skipForward()
    }

    /// Previous track undoes the last dislike if the undo window is still open
    private func skipBackWithUndo() {
        if dislikeManager.lastDislike != nil {
            dislikeManager.undoLastDislike()
            ratingState = .none
        }
        player.skipBack()
    }

    /// Shared logic: dislike the current song on the current station, then skip
    private func recordDislikeAndSkip() {
        Task {
            if let songID = currentSongID, player.currentStation != .none {
                dislikeManager.dislike(songID: songID, on: player.currentStation)
            }
            ratingState = .disliked
            player.skipForward()
        }
    }

    /// Auto-skip disliked songs — call this from .onChange of currentSongTitle
    private func autoSkipIfDisliked() {
        guard let songID = currentSongID,
              player.currentStation != .none,
              dislikeManager.isDisliked(songID: songID, on: player.currentStation) else {
            // Song is not disliked — clear undo window from previous skip
            dislikeManager.clearUndo()
            return
        }
        // This song is disliked on this station — auto-skip without recording again
        player.skipForward()
    }

    private var currentSongID: String? {
        guard let entry = ApplicationMusicPlayer.shared.queue.currentEntry,
              case let .song(song) = entry.item else { return nil }
        return song.id.rawValue
    }

    private var currentSongShareURL: URL? {
        guard let entry = ApplicationMusicPlayer.shared.queue.currentEntry,
              case let .song(song) = entry.item else { return nil }
        if let url = song.url { return url }
        // Fallback: build Apple Music link from song ID
        return URL(string: "https://music.apple.com/song/\(song.id.rawValue)")
    }

    // MARK: - Button Styles

    private func transportButton(icon: String, size: CGFloat, prominent: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [dark.opacity(0.8), Color(red: 0.08, green: 0.12, blue: 0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            LinearGradient(
                                colors: [border.opacity(0.6), border.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            Image(systemName: icon)
                .foregroundStyle(prominent ? tint : accent.opacity(0.8))
                .shadow(color: prominent ? glow.opacity(0.4) : .clear, radius: 3)
        }
        .frame(width: prominent ? 64 : 52, height: prominent ? 52 : 44)
    }

    private func modeButton(icon: String, label: String, isActive: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [dark.opacity(0.8), Color(red: 0.08, green: 0.12, blue: 0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    isActive ? tint.opacity(0.8) : border.opacity(0.6),
                                    isActive ? tint.opacity(0.4) : border.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .foregroundStyle(isActive ? tint : accent.opacity(0.5))
            .shadow(color: isActive ? glow.opacity(0.4) : .clear, radius: 3)
        }
        .frame(height: 36)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
