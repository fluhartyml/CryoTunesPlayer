//
//  CryoSleepTimerPicker.swift
//  CryoTunes Player
//
//  Local copy — CryoKit serves data only, apps own their views.
//

import SwiftUI
import CryoKit

struct CryoSleepTimerPicker: View {
    @Bindable var player: MusicPlaybackManager
    let tint: Color
    let accent: Color
    let dark: Color
    let border: Color

    @AppStorage("selectedSleepTimer") private var selectedSleepTimerRaw: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SleepTimerOption.allCases, id: \.self) { option in
                Button {
                    selectedSleepTimerRaw = option.rawValue
                    player.startSleepTimer(minutes: option.rawValue)
                } label: {
                    Text(option.displayName)
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
}
