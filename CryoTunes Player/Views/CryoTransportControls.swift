//
//  CryoTransportControls.swift
//  CryoTunes Player
//
//  Local copy — CryoKit serves data only, apps own their views.
//

import SwiftUI
import CryoKit

struct CryoTransportControls: View {
    @Bindable var player: MusicPlaybackManager
    let tint: Color
    let accent: Color
    let dark: Color
    let border: Color
    let glow: Color

    var body: some View {
        VStack(spacing: 12) {
            // Row 1: Transport
            HStack(spacing: 32) {
                Button { player.skipBack() } label: {
                    transportButton(icon: "backward.end.fill", size: 24)
                }

                Button { player.togglePlayPause() } label: {
                    transportButton(
                        icon: player.isPlaying ? "pause.fill" : "play.fill",
                        size: 32,
                        prominent: true
                    )
                }

                Button { player.skipForward() } label: {
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
        }
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
