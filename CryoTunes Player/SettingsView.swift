//
//  SettingsView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import SwiftUI
import PhotosUI
import AVKit

struct SettingsView: View {
    @Bindable var playerManager: MusicPlayerManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("backgroundImagePath") private var backgroundImagePath: String = ""
    @AppStorage("selectedSleepTimer") private var selectedSleepTimerRaw: Int = 0

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var expandedCategories: Set<StationCategory> = []
    @State private var expandedDecades: Set<BillboardDecade> = []

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

                    // Background Image
                    backgroundSection

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

    // MARK: - Background Image

    private var backgroundSection: some View {
        sectionContainer(title: "Background Image") {
            VStack(spacing: 12) {
                if !backgroundImagePath.isEmpty {
                    HStack {
                        Text("Custom background set")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(iceAccent.opacity(0.7))
                        Spacer()
                        Button("Remove") {
                            removeBackgroundImage()
                        }
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.red.opacity(0.8))
                    }
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundStyle(iceAccent)
                        Text(backgroundImagePath.isEmpty ? "Choose Image" : "Change Image")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(iceBlue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 4).fill(iceDark))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(iceBorder.opacity(0.4), lineWidth: 1)
                    )
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        await saveBackgroundImage(from: newItem)
                    }
                }
            }
        }
    }

    private func saveBackgroundImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent("background.jpg")

        do {
            try data.write(to: filePath)
            await MainActor.run {
                backgroundImagePath = "background.jpg"
            }
        } catch {
            print("Failed to save background: \(error)")
        }
    }

    private func removeBackgroundImage() {
        if !backgroundImagePath.isEmpty {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fullPath = documentsPath.appendingPathComponent(backgroundImagePath)
            try? FileManager.default.removeItem(at: fullPath)
        }
        backgroundImagePath = ""
    }

    // MARK: - Leader/Follower

    // MARK: - Leader/Follower (v1.1 — requires CloudKit container setup on portal)
    // followerSection removed from UI until iCloud.com.fluhartyml.Tally-Matrix-Clock
    // container is registered for com.Tangerine.CryoTunesPlayer on developer.apple.com

    // MARK: - About

    private var aboutSection: some View {
        sectionContainer(title: "About") {
            VStack(spacing: 6) {
                HStack {
                    Text("CryoTunes Player")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                    Spacer()
                    Text("v1.0")
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
