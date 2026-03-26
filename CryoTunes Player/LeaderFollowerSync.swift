//
//  LeaderFollowerSync.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//
//  Connects to the Tally Matrix Clock CloudKit container as a follower.
//  Polls every 1 second for leader setting changes (station, sleep timer).
//  CryoTunes is always a follower — it never writes to the leader record.
//

import Foundation
import CloudKit

@Observable
class LeaderFollowerSync {
    var isConnected = false
    var leaderDeviceName = ""
    var leaderStation = ""
    var leaderSleepTimerMinutes = 0
    var followerEnabled = false {
        didSet {
            UserDefaults.standard.set(followerEnabled, forKey: "followerEnabled")
            if followerEnabled {
                startPolling()
            } else {
                stopPolling()
                isConnected = false
                leaderDeviceName = ""
            }
        }
    }

    private var container: CKContainer? {
        guard followerEnabled else { return nil }
        return CKContainer(identifier: "iCloud.com.fluhartyml.Tally-Matrix-Clock")
    }
    private var pollTimer: Timer?
    private var lastStationRaw = ""
    private var lastSleepMinutes = 0

    var onStationChanged: ((MusicStationOption) -> Void)?
    var onSleepTimerChanged: ((Int) -> Void)?

    init() {
        // Always start in leader mode — user must manually enable follower
        followerEnabled = false
        UserDefaults.standard.set(false, forKey: "followerEnabled")
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pullFromCloud()
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func pullFromCloud() {
        guard let container else { return }
        let recordID = CKRecord.ID(recordName: "SharedSettings", zoneID: .default)
        let database = container.publicCloudDatabase

        database.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self, let record else {
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
                return
            }

            DispatchQueue.main.async {
                self.isConnected = true

                // Leader device name
                if let name = record["leaderDeviceName"] as? String {
                    self.leaderDeviceName = name
                }

                // Station change
                if let stationRaw = record["musicStationRaw"] as? String,
                   stationRaw != self.lastStationRaw {
                    self.lastStationRaw = stationRaw
                    self.leaderStation = stationRaw
                    if let station = MusicStationOption(rawValue: stationRaw) {
                        self.onStationChanged?(station)
                    }
                }

                // Sleep timer change
                if let sleepMinutes = record["sleepTimerMinutes"] as? Int,
                   sleepMinutes != self.lastSleepMinutes {
                    self.lastSleepMinutes = sleepMinutes
                    self.leaderSleepTimerMinutes = sleepMinutes
                    self.onSleepTimerChanged?(sleepMinutes)
                }
            }
        }
    }
}
