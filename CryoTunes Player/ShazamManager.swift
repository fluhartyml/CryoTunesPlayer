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
    var playlistManager: PlaylistManager?

    private var session = SHSession()
    private var audioEngine = AVAudioEngine()
    /// REM: review 015 (2026-11-24): the 12-second auto-stop, kept so Stop can cancel it.
    private var autoStopTask: Task<Void, Never>?
    /// REM: review 016: was CryoTunes playing when the listen began? If so, resume after.
    private var musicWasPlaying = false

    override init() {
        super.init()
        session.delegate = self
    }

    func startListening() async {
        if isListening {
            stopListening()
            return
        }

        musicWasPlaying = ApplicationMusicPlayer.shared.state.playbackStatus == .playing
        await MainActor.run {
            isListening = true
            noMatch = false
            matchedSong = nil
            matchedTitle = ""
            matchedArtist = ""
        }

        // REM 11-18: the Mac has no AVAudioSession; AVAudioEngine reads the mic directly.
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error)")
            await MainActor.run { isListening = false }
            return
        }
        #endif

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // REM: review 017 (2026-11-24): the tap runs on the audio thread. It captures the
        // REM: session itself, not self, so it never reaches into a main-actor object.
        let shazamSession = session
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in
            shazamSession.matchStreamingBuffer(buffer, at: nil)
        }

        do {
            try audioEngine.start()
        } catch {
            // REM: review 014: a failed start used to leave the tap installed, and the next
            // REM: press installed a second one, which crashes AVAudioEngine. Clean up now.
            print("Audio engine error: \(error)")
            stopListening()
            return
        }

        // Auto-stop after 12 seconds (cancelled by Stop — review 015)
        autoStopTask?.cancel()
        autoStopTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard !Task.isCancelled, let self, self.isListening else { return }
            self.stopListening()
        }
    }

    func stopListening() {
        autoStopTask?.cancel()
        autoStopTask = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false

        // Restore playback audio session
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        // REM: review 016: pick the music back up if it was playing before the listen.
        if musicWasPlaying {
            musicWasPlaying = false
            Task { try? await ApplicationMusicPlayer.shared.play() }
        }
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
            try await PlaylistManager.libraryAddSong(song)
            // Add to Shazamed Songs playlist
            await playlistManager?.addToShazamPlaylist(song)
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
