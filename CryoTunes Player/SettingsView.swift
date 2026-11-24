//
//  SettingsView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import SwiftUI
import AVKit
import MusicKit

struct SettingsView: View {
    /// Review 043: one Dynamic Type multiplier for every font in this view (see Platform.swift).
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

    @Bindable var playerManager: MusicPlaybackManager
    var dislikeManager: DislikeManager
    var stationFailureMonitor: StationFailureMonitor
    /// REM 2026-11-19 22:2x — his word: "can you not have them on a regular iphone?" Card
    /// Position shows on the Duo, iPad and Mac only; a regular iPhone uses the default spots.
    var showsCardPosition: Bool = true
    @Environment(\.dismiss) private var dismiss
    @State private var showingFeedback = false
    @State private var showingStationSuggestion = false
    @State private var showResetAllConfirm = false

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

                    // Card Position (not on a regular iPhone)
                    if showsCardPosition {
                        cardPositionSection
                    }

                    // Manage Dislikes
                    if !dislikeManager.stationsWithDislikes().isEmpty {
                        dislikesSection
                    }

                    // AirPlay (not on Vision Pro, review 018)
                    #if !os(visionOS)
                    airPlaySection
                    #endif

                    // About
                    aboutSection
                }
                .padding(16)
            }
            .background(Color(red: 0.06, green: 0.09, blue: 0.16))
            .navigationTitle("Settings")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(iceBlue)
                }
            }
            .darkNavigationBar()
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Station Picker (CryoKit shared view)

    private var stationSection: some View {
        sectionContainer(title: "Stations") {
            CryoStationPicker(
                player: playerManager,
                stationFailureMonitor: stationFailureMonitor,
                tint: iceBlue,
                accent: iceAccent,
                border: iceBorder
            )
        }
    }

    // MARK: - Sleep Timer (CryoKit shared view)

    private var sleepTimerSection: some View {
        sectionContainer(title: "Sleep Timer") {
            CryoSleepTimerPicker(
                player: playerManager,
                tint: iceBlue,
                accent: iceAccent,
                dark: iceDark,
                border: iceBorder
            )
        }
    }

    // MARK: - Card Position

    /// REM 2026-11-19 — the listener picks a quadrant for each glass card. His word, 18:24:
    /// "can we have preset options the user can choose to reposition?", then 18:27: quadrants,
    /// "either of the cards". Picking the other card's quadrant swaps the two. The buttons are a
    /// 2 × 2 grid laid out like the screen, so each button sits where its card will go. Saved,
    /// so the choice holds after a relaunch and in every pose. On screens under 700 points wide
    /// only top or bottom applies, and the Stations card stays here in Settings.
    @AppStorage(CardQuadrant.playerKey) private var playerQuadrantRaw = CardQuadrant.bottomRight.rawValue
    @AppStorage(CardQuadrant.stationsKey) private var stationsQuadrantRaw = CardQuadrant.bottomLeft.rawValue

    private var cardPositionSection: some View {
        sectionContainer(title: "Card Position") {
            VStack(alignment: .leading, spacing: 16) {
                quadrantPicker(title: "Player card", key: "player", mine: $playerQuadrantRaw, other: $stationsQuadrantRaw)
                Divider().overlay(iceBorder.opacity(0.2))
                quadrantPicker(title: "Stations card", key: "stations", mine: $stationsQuadrantRaw, other: $playerQuadrantRaw)
            }
        }
    }

    private func quadrantPicker(title: String, key: String, mine: Binding<String>, other: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18 * textScale, weight: .semibold, design: .monospaced))
                .foregroundStyle(iceBlue)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow { quadrantButton(.topLeft, key: key, mine: mine, other: other); quadrantButton(.topRight, key: key, mine: mine, other: other) }
                GridRow { quadrantButton(.bottomLeft, key: key, mine: mine, other: other); quadrantButton(.bottomRight, key: key, mine: mine, other: other) }
            }
        }
    }

    private func quadrantButton(_ q: CardQuadrant, key: String, mine: Binding<String>, other: Binding<String>) -> some View {
        let selected = mine.wrappedValue == q.rawValue
        return Button {
            if other.wrappedValue == q.rawValue { other.wrappedValue = mine.wrappedValue }
            mine.wrappedValue = q.rawValue
        } label: {
            Text(q.label)
                .font(.system(size: 18 * textScale, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(selected ? .black : iceBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 4).fill(selected ? iceAccent : iceDark))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(iceBorder.opacity(0.4), lineWidth: 1))
        }
        .accessibilityLabel(q.label)
        .accessibilityIdentifier("quad.\(key).\(q.rawValue)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - AirPlay

    #if !os(visionOS)
    private var airPlaySection: some View {
        sectionContainer(title: "AirPlay") {
            AirPlayButton()
                .frame(height: 44)
        }
    }

    #endif

    // MARK: - Manage Dislikes

    private var dislikesSection: some View {
        sectionContainer(title: "Manage Dislikes") {
            VStack(spacing: 8) {
                ForEach(dislikeManager.stationsWithDislikes(), id: \.station) { item in
                    HStack {
                        Text(item.station.rawValue)
                            .font(.system(size: 18 * textScale, weight: .medium, design: .monospaced))
                            .foregroundStyle(iceBlue)
                            .lineLimit(1)

                        Spacer()

                        Text("\(item.count)")
                            .font(.system(size: 18 * textScale, design: .monospaced))
                            .foregroundStyle(iceBorder)

                        Button {
                            dislikeManager.resetStation(item.station)
                        } label: {
                            Text("Reset")
                                .font(.system(size: 18 * textScale, weight: .medium, design: .monospaced))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 4)

                    if item.station != dislikeManager.stationsWithDislikes().last?.station {
                        Divider().overlay(iceBorder.opacity(0.2))
                    }
                }

                Divider().overlay(iceBorder.opacity(0.2))

                Button {
                    showResetAllConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 18 * textScale))
                        Text("Reset All Dislikes")
                            .font(.system(size: 18 * textScale, weight: .medium, design: .monospaced))
                        Spacer()
                    }
                    .foregroundStyle(.red.opacity(0.8))
                }
                .alert("Reset All Dislikes?", isPresented: $showResetAllConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset All", role: .destructive) {
                        dislikeManager.resetAll()
                    }
                } message: {
                    Text("This will clear all disliked songs on every station.")
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        sectionContainer(title: "About") {
            VStack(spacing: 6) {
                HStack {
                    Text("CryoTunes Player")
                        .font(.system(size: 18 * textScale, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                    Spacer()
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                        .font(.system(size: 18 * textScale, design: .monospaced))
                        .foregroundStyle(iceBorder)
                }
                HStack {
                    Text("Michael Lee Fluharty")
                        .font(.system(size: 18 * textScale, design: .monospaced))
                        .foregroundStyle(iceBorder.opacity(0.7))
                    Spacer()
                }
                HStack {
                    Text("Engineered with Claude by Anthropic")
                        .font(.system(size: 18 * textScale, design: .monospaced))
                        .foregroundStyle(iceBorder.opacity(0.5))
                    Spacer()
                }
                // REM 2026-11-19 — the  Weather attribution link left with the weather (his word
                // 18:54: "weater and everything to do with the lcd"); the app shows no weather now.
                Divider().overlay(iceBorder.opacity(0.2))
                Button {
                    showingStationSuggestion = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 18 * textScale))
                        Text("Suggest a Station")
                            .font(.system(size: 18 * textScale, weight: .medium, design: .monospaced))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18 * textScale))
                    }
                    .foregroundStyle(iceAccent)
                }
                .sheet(isPresented: $showingStationSuggestion) {
                    FeedbackView(appName: "CryoTunes Player", initialType: .stationSuggestion)
                }
                Divider().overlay(iceBorder.opacity(0.2))
                Button {
                    showingFeedback = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope")
                            .font(.system(size: 18 * textScale))
                        Text("Send Feedback")
                            .font(.system(size: 18 * textScale, weight: .medium, design: .monospaced))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18 * textScale))
                    }
                    .foregroundStyle(iceAccent)
                }
                .sheet(isPresented: $showingFeedback) {
                    FeedbackView(appName: "CryoTunes Player")
                }
                // REM: review sheet 028 (his "okay lock it" 2026-11-24): Privacy Policy and
                // REM: Support rows, linking the pages on fluharty.me.
                Divider().overlay(iceBorder.opacity(0.2))
                aboutLink("Privacy Policy", symbol: "hand.raised",
                          url: "https://fluharty.me/privacy.html")
                Divider().overlay(iceBorder.opacity(0.2))
                aboutLink("Support", symbol: "questionmark.circle",
                          url: "https://fluharty.me/cryotunes-player-support.html")
            }
        }
    }

    @ViewBuilder
    private func aboutLink(_ title: String, symbol: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 4) {
                    Image(systemName: symbol)
                        .font(.system(size: 18 * textScale))
                    Text(title)
                        .font(.system(size: 18 * textScale, weight: .medium, design: .monospaced))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 18 * textScale))
                }
                .foregroundStyle(iceAccent)
            }
            .accessibilityLabel(title)
        }
    }

    // MARK: - Section Container

    private func sectionContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 18 * textScale, weight: .bold, design: .monospaced))
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

// REM: review 018 (2026-11-24): Vision Pro has no AirPlay route picker (AVRoutePickerView is
// REM: unavailable there; the wearer picks audio output in Control Center), so the AirPlay row
// REM: is left out on visionOS rather than shown dead (no placeholders).
#if os(iOS)
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = UIColor(red: 0.5, green: 0.78, blue: 0.95, alpha: 1.0)
        routePickerView.activeTintColor = UIColor(red: 0.65, green: 0.82, blue: 0.95, alpha: 1.0)
        return routePickerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#elseif os(macOS)
// REM: Mac twin of the AirPlay picker (AVRoutePickerView is an NSView there).
struct AirPlayButton: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let routePickerView = AVRoutePickerView()
        routePickerView.isRoutePickerButtonBordered = false
        routePickerView.setRoutePickerButtonColor(
            NSColor(red: 0.5, green: 0.78, blue: 0.95, alpha: 1.0), for: .normal)
        routePickerView.setRoutePickerButtonColor(
            NSColor(red: 0.65, green: 0.82, blue: 0.95, alpha: 1.0), for: .active)
        return routePickerView
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
