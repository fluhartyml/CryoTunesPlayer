//
//  LCDTickerView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import SwiftUI

struct LCDTickerView: View {
    let weatherManager: WeatherManager

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private let silverLight = Color(red: 0.78, green: 0.80, blue: 0.82)
    private let silverDark = Color(red: 0.55, green: 0.58, blue: 0.60)
    private let lcdBackground = Color(red: 0.72, green: 0.75, blue: 0.70)
    private let lcdText = Color(red: 0.15, green: 0.18, blue: 0.15)
    private let speed: Double = 30 // points per second

    private var tickerText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: Date())
        formatter.dateFormat = "EEE MMM d"
        let date = formatter.string(from: Date())

        var parts: [String] = [time, date]
        if !weatherManager.locationName.isEmpty {
            parts.append(weatherManager.locationName)
        }
        if weatherManager.temperature != "--" {
            parts.append("\(weatherManager.temperature) \(weatherManager.condition)")
        }
        return parts.joined(separator: "  ·  ")
    }

    private let tickerFont = Font.system(size: 14, weight: .bold, design: .monospaced)

    var body: some View {
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
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(silverDark.opacity(0.3), lineWidth: 0.5)
                        .padding(3)
                )

            // Scrolling text
            TimelineView(.animation) { context in
                GeometryReader { geo in
                    let cw = geo.size.width - 16
                    let text = tickerText
                    let needsScroll = textWidth > cw && textWidth > 0 && cw > 0

                    if needsScroll {
                        let totalDistance = textWidth + cw
                        let cycleDuration = totalDistance / speed
                        let elapsed = context.date.timeIntervalSinceReferenceDate
                        let offset = elapsed.truncatingRemainder(dividingBy: cycleDuration) * speed

                        Text(text)
                            .font(tickerFont)
                            .foregroundStyle(lcdText)
                            .fixedSize()
                            .offset(x: cw - offset)
                            .frame(width: cw, alignment: .leading)
                            .clipped()
                    } else {
                        Text(text)
                            .font(tickerFont)
                            .foregroundStyle(lcdText)
                            .fixedSize()
                            .frame(width: cw)
                    }
                }
                .padding(.horizontal, 8)
            }

            // Hidden text for measurement — must not affect parent layout
            Color.clear
                .frame(width: 0, height: 0)
                .overlay(
                    Text(tickerText)
                        .font(tickerFont)
                        .fixedSize()
                        .hidden()
                        .background(
                            GeometryReader { textGeo in
                                Color.clear
                                    .onAppear { textWidth = textGeo.size.width }
                                    .onChange(of: tickerText) { _, _ in
                                        textWidth = textGeo.size.width
                                    }
                            }
                        )
                )
        }
        .frame(height: 30)
        .onAppear {
            // Trigger initial measurement
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                textWidth = textWidth // force re-eval
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    containerWidth = geo.size.width - 16
                }
            }
        )
    }
}
