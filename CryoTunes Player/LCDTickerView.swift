//
//  LCDTickerView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import SwiftUI

struct LCDTickerView: View {
    let weatherManager: WeatherManager

    @State private var currentTime = ""
    @State private var currentDate = ""
    @State private var tickerOffset: CGFloat = 0
    @State private var tickerWidth: CGFloat = 0

    private let silverLight = Color(red: 0.78, green: 0.80, blue: 0.82)
    private let silverDark = Color(red: 0.55, green: 0.58, blue: 0.60)
    private let lcdBackground = Color(red: 0.72, green: 0.75, blue: 0.70)
    private let lcdText = Color(red: 0.15, green: 0.18, blue: 0.15)

    private var tickerText: String {
        var parts: [String] = []
        parts.append(currentTime)
        parts.append(currentDate)
        if !weatherManager.locationName.isEmpty {
            parts.append(weatherManager.locationName)
        }
        if weatherManager.temperature != "--" {
            parts.append("\(weatherManager.temperature) \(weatherManager.condition)")
        }
        return parts.joined(separator: "  ·  ")
    }

    var body: some View {
        // Silver LCD bezel
        ZStack {
            // Outer bezel
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [silverLight, silverDark, silverLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Inner LCD screen
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            lcdBackground.opacity(0.9),
                            lcdBackground,
                            lcdBackground.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(3)
                .overlay(
                    // LCD pixel grid effect
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(silverDark.opacity(0.3), lineWidth: 0.5)
                        .padding(3)
                )

            // Scrolling text
            GeometryReader { geo in
                let containerWidth = geo.size.width - 16

                Text(tickerText)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(lcdText)
                    .fixedSize()
                    .background(
                        GeometryReader { textGeo in
                            Color.clear
                                .onAppear {
                                    tickerWidth = textGeo.size.width
                                }
                                .onChange(of: tickerText) { _, _ in
                                    tickerWidth = textGeo.size.width
                                }
                        }
                    )
                    .offset(x: tickerWidth > containerWidth ? tickerOffset : (containerWidth - tickerWidth) / 2)
                    .onAppear {
                        startScrolling(containerWidth: containerWidth)
                    }
                    .onChange(of: tickerWidth) { _, _ in
                        startScrolling(containerWidth: containerWidth)
                    }
            }
            .padding(.horizontal, 8)
            .clipped()
        }
        .frame(height: 30)
        .onAppear {
            updateTime()
            startClock()
        }
    }

    private func startScrolling(containerWidth: CGFloat) {
        guard tickerWidth > containerWidth else {
            tickerOffset = 0
            return
        }

        tickerOffset = containerWidth
        withAnimation(
            .linear(duration: Double(tickerWidth + containerWidth) / 25)
            .repeatForever(autoreverses: false)
        ) {
            tickerOffset = -tickerWidth
        }
    }

    private func startClock() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTime()
        }
    }

    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        currentTime = formatter.string(from: Date())

        formatter.dateFormat = "EEE MMM d"
        currentDate = formatter.string(from: Date())
    }
}
