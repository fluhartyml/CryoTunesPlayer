// MARK: - CryoTunes Player — Developer Notes
// Version: 1.0
// Developer: Michael Lee Fluharty
// Engineered with: Claude by Anthropic
// License: GPL v3
// Created: 2026-03-26
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
//   [ ] Queue position persistence (resume exact track on relaunch)
//   [ ] Background image persistence survives clean build (dev-only issue, works for App Store users)
//   [ ] Graceful error messages (no subscription, no network)
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
