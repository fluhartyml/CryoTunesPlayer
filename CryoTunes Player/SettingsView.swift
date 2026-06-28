//
//  SettingsView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import SwiftUI
import AVKit
import MessageUI
import MusicKit

struct SettingsView: View {
    @Bindable var playerManager: MusicPlaybackManager
    var dislikeManager: DislikeManager
    var stationFailureMonitor: StationFailureMonitor
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

                    // Manage Dislikes
                    if !dislikeManager.stationsWithDislikes().isEmpty {
                        dislikesSection
                    }

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

    // MARK: - AirPlay

    private var airPlaySection: some View {
        sectionContainer(title: "AirPlay") {
            AirPlayButton()
                .frame(height: 44)
        }
    }

    // MARK: - Manage Dislikes

    private var dislikesSection: some View {
        sectionContainer(title: "Manage Dislikes") {
            VStack(spacing: 8) {
                ForEach(dislikeManager.stationsWithDislikes(), id: \.station) { item in
                    HStack {
                        Text(item.station.rawValue)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundStyle(iceBlue)
                            .lineLimit(1)

                        Spacer()

                        Text("\(item.count)")
                            .font(.system(size: 18, design: .monospaced))
                            .foregroundStyle(iceBorder)

                        Button {
                            dislikeManager.resetStation(item.station)
                        } label: {
                            Text("Reset")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
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
                            .font(.system(size: 18))
                        Text("Reset All Dislikes")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
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
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                    Spacer()
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundStyle(iceBorder)
                }
                HStack {
                    Text("Michael Lee Fluharty")
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundStyle(iceBorder.opacity(0.7))
                    Spacer()
                }
                HStack {
                    Text("Engineered with Claude by Anthropic")
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundStyle(iceBorder.opacity(0.5))
                    Spacer()
                }
                Divider().overlay(iceBorder.opacity(0.2))
                Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("Weather")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 18))
                    }
                    .foregroundStyle(iceBorder.opacity(0.5))
                }
                Divider().overlay(iceBorder.opacity(0.2))
                Button {
                    showingStationSuggestion = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 18))
                        Text("Suggest a Station")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18))
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
                            .font(.system(size: 18))
                        Text("Send Feedback")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18))
                    }
                    .foregroundStyle(iceAccent)
                }
                .sheet(isPresented: $showingFeedback) {
                    FeedbackView(appName: "CryoTunes Player")
                }
            }
        }
    }

    // MARK: - Section Container

    private func sectionContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 18, weight: .bold, design: .monospaced))
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
