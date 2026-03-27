//
//  ShazamManager.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/27/26.
//

import Foundation
import ShazamKit
import AVFoundation
import MusicKit

@Observable
class ShazamManager: NSObject, SHSessionDelegate {
    var isListening = false
    var matchedSong: SHMatchedMediaItem?
    var matchedTitle = ""
    var matchedArtist = ""
    var noMatch = false
    var addedToLibrary = false

    private var session = SHSession()
    private var audioEngine = AVAudioEngine()

    override init() {
        super.init()
        session.delegate = self
    }

    func startListening() async {
        if isListening {
            stopListening()
            return
        }

        await MainActor.run {
            isListening = true
            noMatch = false
            matchedTitle = ""
            matchedArtist = ""
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error)")
            await MainActor.run { isListening = false }
            return
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.session.matchStreamingBuffer(buffer, at: nil)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine error: \(error)")
            await MainActor.run { isListening = false }
        }

        // Auto-stop after 12 seconds
        Task {
            try? await Task.sleep(for: .seconds(12))
            await MainActor.run {
                if self.isListening {
                    self.stopListening()
                }
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false

        // Restore playback audio session
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - SHSessionDelegate

    nonisolated func session(_ session: SHSession, didFind match: SHMatch) {
        guard let item = match.mediaItems.first else { return }
        Task { @MainActor in
            self.matchedSong = item
            self.matchedTitle = item.title ?? "Unknown"
            self.matchedArtist = item.artist ?? "Unknown"
            self.stopListening()
            await self.addToLibrary(item)
        }
    }

    func addToLibrary(_ item: SHMatchedMediaItem) async {
        guard let appleMusicID = item.appleMusicID else { return }
        do {
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(appleMusicID))
            let response = try await request.response()
            guard let song = response.items.first else { return }
            try await MusicLibrary.shared.add(song)
            await MainActor.run { addedToLibrary = true }
        } catch {
            print("Add to library error: \(error)")
        }
    }

    nonisolated func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: (any Error)?) {
        Task { @MainActor in
            self.noMatch = true
            self.stopListening()
        }
    }
}
