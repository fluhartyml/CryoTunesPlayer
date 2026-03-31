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

    // MARK: - Station Picker (CryoKit shared view)

    private var stationSection: some View {
        sectionContainer(title: "Stations") {
            CryoStationPicker(
                player: playerManager,
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
