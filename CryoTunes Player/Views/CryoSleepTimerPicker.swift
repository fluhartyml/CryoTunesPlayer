//
//  CryoSleepTimerPicker.swift
//  CryoTunes Player
//
//  Local copy — CryoKit serves data only, apps own their views.
//

import SwiftUI

struct CryoSleepTimerPicker: View {
    @Bindable var player: MusicPlaybackManager
    let tint: Color
    let accent: Color
    let dark: Color
    let border: Color

    @AppStorage("selectedSleepTimer") private var selectedSleepTimerRaw: Int = 0

    // REM: review 043 (2026-11-24) — the buttons now grow with Larger Text. At the big
    // REM: accessibility sizes six in one row broke words mid-word ("Son/g", "30/m"). Contingent
    // REM: sizing (his 11-14 rule): one row of six when it fits, else two rows of three, else three rows of two, at the
    // REM: listener's full size. Words never break (lineLimit 1).
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ForEach(SleepTimerOption.allCases, id: \.self) { option in timerButton(option) }
            }
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(Array(SleepTimerOption.allCases.prefix(3)), id: \.self) { option in timerButton(option) }
                }
                HStack(spacing: 8) {
                    ForEach(Array(SleepTimerOption.allCases.dropFirst(3)), id: \.self) { option in timerButton(option) }
                }
            }
            // Largest sizes: three rows of two.
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(Array(SleepTimerOption.allCases.dropFirst(row * 2).prefix(2)), id: \.self) { option in timerButton(option) }
                    }
                }
            }
        }
        .onChange(of: player.sleepTimerEnd) { _, newValue in
            if newValue == nil {
                selectedSleepTimerRaw = 0
            }
        }
        .onAppear {
            if player.sleepTimerEnd == nil {
                selectedSleepTimerRaw = 0
            }
        }
    }

    private func timerButton(_ option: SleepTimerOption) -> some View {
        Button {
            selectedSleepTimerRaw = option.rawValue
            player.startSleepTimer(minutes: option.rawValue)
        } label: {
            Text(option.displayName)
                .lineLimit(1)
                // ViewThatFits measures the row at the words' real width (no squeeze to "So…").
                .fixedSize()
                .foregroundStyle(selectedSleepTimerRaw == option.rawValue ? .black : tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selectedSleepTimerRaw == option.rawValue ? accent : dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(border.opacity(0.4), lineWidth: 1)
                )
        }
        .accessibilityLabel(option.accessibilityName)
    }
}
