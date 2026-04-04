// MARK: - CryoTunes Player — Developer Notes
// Version: 1.0
// Developer: Michael Lee Fluharty
// Engineered with: Claude by Anthropic
// License: GPL v3
// Created: 2026-03-26
//
// ============================================================
// CURRENT STATUS (APR 02 2026)
// ============================================================
//
// v2.4 submitted APR 02 10:18 AM, waiting for review.
// No further code changes needed. Waiting on Apple.
//
// CryoKit dependency: DIAMOND RULE in effect.
// Claude may NOT remove, subtract, or modify code within CryoKit.
// Claude may add to it with express written consent from human ONLY.
//
// ============================================================
// PROJECT ROADMAP
// ============================================================
//
// v1.0 — "Fidget Spinner" Release
// --------------------------------
// Core: Retro 90s music player for iPhone
// Theme: Ice blue motif inspired by Winamp, Napster, LimeWire era
//
// Features:
//   [x] Xcode project setup
//   [x] GitHub repo (fluhartyml/CryoTunesPlayer)
//   [x] Wiki with hero icon
//   [x] App icons (light + dark variants)
//   [x] Retro 90s player UI (ice blue motif)
//   [x] MusicKit integration — streaming playback
//   [x] 80+ music stations (reuse from Tally Matrix Clock)
//       - Popular Hits decade picker (1958-2025)
//       - Genre stations: Big Band, Jazz Age, Ragtime, etc.
//       - Three-level navigation: Category → Decade → Year
//   [x] Album art display with song title + artist
//   [x] LCD ticker (time, date, local weather via WeatherKit)
//   [x] Station persistence across launches (no auto-play)
//   [ ] Custom background image (PhotosPicker, user-defined, persisted)
//   [ ] Sleep timer (30m, 1h, 2h, 4h)
//   [ ] AirPlay 2 output picker
//   [x] Play/Pause/Skip/Stop controls
//   [ ] Now Playing info on lock screen
//   [x] Settings screen
//
// v1.1+ — Future Enhancements (raise iOS minimum as needed)
// ----------------------------------------------------------
//   [ ] Tally Matrix Clock leader/follower sync via CloudKit
//   [ ] iCloud sync for settings + background image across devices
//   [ ] ShazamKit song recognition (requires NSMicrophoneUsageDescription)
//   [ ] Dark/light automatic icon switching (iOS 18+)
//   [ ] Additional color themes beyond ice blue
//   [ ] Landscape mode
//   [ ] iPad support
//   [ ] Widget for home screen
//   [ ] Easter egg (hidden interaction — tap title or idle screen)
//   [ ] Queue position persistence (resume exact track on relaunch)
//   [ ] Custom background image (z-ordering issue: image renders over UI — needs proper layer fix)
//   [ ] Background image persistence survives clean build (dev-only issue, works for App Store users)
//   [ ] Graceful error messages (no subscription, no network)
//
// ============================================================
// APP STORE CONNECT
// ============================================================
//
// ** Claude: Update this section as information becomes available.
// ** Keep current with every submission. This is the source of truth.
//
// App Name: CryoTunes Player
// App Apple ID: 6761222456
// Bundle ID: com.Tangerine.CryoTunes-Player
// SKU: CryoTunesPlayer
// Category: Music
// URL: https://apps.apple.com/us/app/cryotunes-player/id6761222456
//
// Current Version: 2.4 (build 2.5)
// Status: Submitting for review
//
// Subtitle: Designed for iPad
//
// Promotional Text (170 char max, updatable anytime):
//   Retro 90s music player. 80+ stations, Shazam, shuffle &
//   repeat, sleep timer, AirPlay 2. Browse your playlists —
//   tap to reveal tracks.
//
// Description:
//   CryoTunes Player is a retro 90s-inspired music player with
//   an ice blue LCD aesthetic. Stream 80+ curated stations across
//   genres, Billboard decade charts from 1958 to 2025, nature
//   sounds, focus frequencies, and ASMR white noise — or browse
//   your own music library with playlists, albums, and artists.
//
// What's New (v2.4):
//   - Playlist reveal: tap any playlist to see tracks
//   - Song counts on every playlist
//   - Play All or pick a song to start from
//   - 18pt readable fonts in My Music
//
// What's New (v2.3):
//   - Track progress bar with elapsed, remaining, and total time
//   - Next/previous track buttons
//
// What's New (v2.2):
//   - Shuffle, Repeat All, and Repeat One playback controls
//   - My Music: browse and play your Playlists, Albums, and Artists
//   - CryoKit shared engine for faster updates across apps
//
// Privacy: No ads. No tracking. All data stays on your device.
// License: GPL v3
//
// Version History:
//   v1.0 (2026-03-26) — Initial release, retro player, 80+ stations
//   v2.1 (2026-03-31) — CryoKit, shuffle/repeat, My Music
//   v2.2 (2026-03-31) — CryoKit shared views, submitted
//   v2.3 (2026-04-01) — Progress bar, next/prev track icons
//   v2.4 (2026-04-02) — Playlist reveal, song counts, 18pt fonts
//
// ============================================================
// SHAKEDOWN CHECKLIST — Complete before App Store submission
// ============================================================
//
// UI & Layout:
//   [ ] Ice blue motif renders correctly on all iPhone sizes
//   [ ] Retro player UI elements are tappable and responsive
//   [ ] Album art displays correctly (various aspect ratios)
//   [ ] Custom background image loads, displays, persists across launches
//   [ ] Background image doesn't obscure player controls
//   [ ] Settings screen opens/closes cleanly
//   [ ] All text is readable at all font sizes (accessibility)
//
// Music Playback:
//   [ ] MusicKit authorization prompt appears on first launch
//   [ ] Stations play correct content (spot-check 5+ stations)
//   [ ] Popular Hits decade picker — test 1958, 1981, 2000, 2025
//   [ ] Genre stations — test Big Band, Jazz Age, Ragtime
//   [ ] Play/Pause works
//   [ ] Skip forward works
//   [ ] Skip back works
//   [ ] Album art updates on track change
//   [ ] Song title + artist update on track change
//   [ ] Music continues when app is backgrounded
//   [ ] Music stops when app is terminated (no background toggle)
//   [ ] Lock screen controls work (play/pause/skip)
//   [ ] Now Playing info shows on lock screen
//
// Sleep Timer:
//   [ ] 30 minute timer stops playback on expiry
//   [ ] 1 hour timer stops playback on expiry
//   [ ] 2 hour timer stops playback on expiry
//   [ ] 4 hour timer stops playback on expiry
//   [ ] Timer countdown visible on screen
//   [ ] Timer "Off" selection cancels active timer
//
// AirPlay:
//   [ ] AirPlay 2 picker appears
//   [ ] Audio routes to selected AirPlay device
//   [ ] Audio routes back to iPhone when AirPlay disconnected
//
// Background Image:
//   [ ] PhotosPicker opens from settings
//   [ ] Selected image saves and displays as background
//   [ ] Image persists after app restart
//   [ ] Removing/changing image works
//   [ ] Default state (no image) looks correct
//
// Edge Cases:
//   [ ] No Apple Music subscription — graceful error message
//   [ ] No network — graceful error message
//   [ ] Interrupt playback with phone call — resumes after
//   [ ] Low power mode — playback unaffected
//   [ ] App backgrounded for extended time — resumes correctly
//
// App Store Prep:
//   [ ] Version number set (1.0, build 1)
//   [ ] Bundle ID confirmed (com.Tangerine.CryoTunes-Player)
//   [ ] App category set (Music)
//   [ ] 10 screenshots curated
//   [ ] App description written
//   [ ] Promotional text written
//   [ ] What's New text written
//   [ ] Privacy policy URL set
//   [ ] Keywords selected
//   [ ] Archive builds clean (no warnings)
//   [ ] Upload to App Store Connect succeeds
//
// ============================================================
