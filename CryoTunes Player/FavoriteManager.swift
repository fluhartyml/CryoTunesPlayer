//
//  FavoriteManager.swift
//  CryoTunes Player
//
//  Wraps Apple Music's personal song rating API for the favorite / unfavorite
//  flow on the thumbs-up and thumbs-down buttons. CryoKit serves data only;
//  this manager lives in the app target.
//
//  Endpoint: PUT https://api.music.apple.com/v1/me/ratings/songs/{id}
//  Body: { "type": "ratings", "attributes": { "value": 1 | -1 } }
//
//  value =  1  →  Love (favorite — adds to system "Favorite Songs" playlist)
//  value = -1  →  Dislike (unfavorite + global "Suggest Less Like This" signal)
//
//  Auth is handled by MusicDataRequest using the user's MusicKit-authorized
//  session. No token plumbing in this file.
//

import Foundation
import MusicKit

@Observable
final class FavoriteManager {
    /// Mark the song as a favorite (love) on Apple Music.
    func favorite(songID: String) async throws {
        try await rate(songID: songID, value: 1)
    }

    /// Mark the song as disliked on Apple Music. Removes the song from the
    /// system "Favorite Songs" playlist and feeds the global recommendation
    /// engine a negative signal.
    func unfavorite(songID: String) async throws {
        try await rate(songID: songID, value: -1)
    }

    private func rate(songID: String, value: Int) async throws {
        guard let url = URL(string: "https://api.music.apple.com/v1/me/ratings/songs/\(songID)") else {
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "type": "ratings",
            "attributes": ["value": value]
        ]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        let request = MusicDataRequest(urlRequest: urlRequest)
        _ = try await request.response()
    }
}
