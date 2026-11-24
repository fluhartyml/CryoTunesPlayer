// MARK: - CryoTunes Player — Developer Notes
// Version: 4.0.1
// Developer: Michael Lee Fluharty
// Engineered with: Claude by Anthropic
// License: GPL v3
// Created: 2026-03-26
//
// ############################################################
// ⚠️⚠️⚠️  REM: TO DO NEXT TIME WE WORK ON CRYOTUNES — ADD CARPLAY  ⚠️⚠️⚠️
// ############################################################
// REM: His word 2026-11-13 18:4x: "cryotunes should have this" — the home pad
// REM: that just came out has no App Store of its own and runs third-party apps
// REM: through CarPlay (his report; Claude couldn't confirm it, it's past Claude's
// REM: knowledge). So CryoTunes needs a CarPlay audio app (CarPlay templates +
// REM: the CarPlay audio entitlement) to appear there and in cars. Not started.
// REM: Raise it with him FIRST when a CryoTunes session opens; build only on his yes.
// REM: 2026-11-24: his yes (review sheet line 032). He SUBMITTED the CarPlay entitlement
// REM: request to Apple 11-24. The CarPlay Entitlement Addendum §2 forbids using the
// REM: CarPlay APIs until Apple grants the entitlement — no CarPlay code before approval.
// ############################################################
//
// ============================================================
// CURRENT STATUS (NOV 24 2026 — v4.0.1, build = git commit count)
// ============================================================
//
// REM: Source review 2026-11-24: Grok's 56-line review sheet
// REM: (~/Downloads/CryoTunes-Player-Amber-Sheet.html) — every line LOCKED with his
// REM: word. Work order = sheet line 054. Highlights: error messages shown on the
// REM: player card (002/035); failed station offers "Tell the Developer" (003);
// REM: playlist/artist/album playback fixes (004–007); dislike undo + iCloud merge
// REM: (008–013); Shazam mic fixes (014–017); Vision Pro kept, build fixed (018);
// REM: location + unused entitlements removed (019/020); privacy manifest (023);
// REM: feedback email = message + app version only (025/026).
//
// v4.0 / 4.0.1 (2026-11-18 → 11-20):
//   • LCD ticker and weather RETIRED (his word 11-19). Album art floods the display
//     as wallpaper: blurred fill behind, whole cover on top.
//   • Quadrant cards (player, Stations, Sleep Timer); Card Position in Settings
//     (not on a regular iPhone — cards use the default spots there).
//   • Stop keeps the album art blank until playback really resumes.
//   • Builds 90–91 layout changes apply to a regular iPhone only; Duo, iPad and
//     Mac keep build 89's layout. Mac build added (Mac icon sizes 16–512).
//   • Shuffle: icon and word shrink together (intentional, his 11-20 word).
//   • Universal image (4.0.1).
//
// v3.0.x (2026-07 → 10-31): 3.0 approved 10-19; 3.0.1 approved 10-31. Year
//   channels play only their own year (top 25 playlists), 2026 added 11-09.
//   No non-exempt encryption declared (10-31).
//
// ============================================================
// STATUS (JUN 28 2026 — v3.0 dev on the iOS 27 / Xcode 27 betas) — history
// ============================================================
//
// v3.0 in development. Today's session (all app-target only, no CryoKit edits):
//   • Adaptive landscape — two-column layout (art | controls) whenever the
//     available area is wider than tall (landscape phone, iPad, unfolded Fold).
//     Geometry / aspect-ratio driven (NOT size classes — iPad mini reports a
//     regular size class in both orientations); no hardcoded sizes; the album
//     art is capped to available height so the LCD ticker can't clip off top.
//   • iOS 27 native Music Picker — "Search Apple Music" row in My Music opens
//     Apple's system musicPicker (full catalog + library). iOS 27-gated; on
//     iOS 26 the row is hidden and My Music is unchanged. Selection binding is
//     an array [Song]; plays the first chosen song after the picker dismisses.
//     NOTE: Apple's picker selects via the + on a row — tapping the TITLE only
//     previews. On-screen hint added so users know to tap + then the checkmark.
//   • App Intents — Play Station / Play-Pause / Skip / Stop / Sleep Timer /
//     What's Playing, surfaced to Siri, Shortcuts, Spotlight, Action Button,
//     and Control Center (App Intents are iOS 16+, so they work on 26 AND 27).
//     Shared player host (CryoPlayerHost) so intents + UI drive the same
//     playback; "CryoTunes" registered as a Siri spoken alias.
//     NOTE: Siri VOICE "play <station>" collides with Siri's built-in media
//     handler (it treats the station as a search term) — the intents are
//     reliable via TAP (Shortcuts / Action Button / Control Center), not always
//     via Siri voice. Apple-side friction, not a CryoTunes bug.
//   • [REMOVED 2026-06-28, commit 28eb21e — the Xcode template widget was never
//     wanted; Lock Screen / StandBy / Control Center now-playing come free from
//     MusicKit.] Widget extension target added. Small interactive transport-controls
//     widget (prev / play-pause / next) built via lightweight widget intents
//     driving ApplicationMusicPlayer directly. Responsive ladder planned:
//     small = controls → medium = + now-playing → large = + find-music /
//     library playlists → extra-large (Fold, 4x6) = full page.
//
// FIXED 2026-07-12 (iOS 27 beta now-playing artwork was blank):
// The root cause was NOT nil artwork. entry.artwork IS present — the Open Album
// sheet renders it perfectly via ArtworkImage (verified on-device, iPhone 16e /
// iOS 27.0). The player FACE used entry.artwork.url() + AsyncImage, and on the
// iOS 27 beta artwork.url() returns a "musickit://" URL that AsyncImage/URLSession
// can't load, so the face fell back to the placeholder. Fix: render the Artwork
// object directly via ArtworkImage (Apple's supported path) instead of resolving
// a URL. See MusicPlaybackManager.currentArtwork + the flooded art in ContentView
// (the framed albumArtView was removed as dead code, review 033, 2026-11-24).
//
// CryoKit: RETIRED. His word 2026-11-24: "we retired cryokit and its hard coded in
// the apps now." The Engine/ files are CryoTunes' own code (vendored 2026-06-28,
// commit 344b210). The old Diamond Rule does NOT apply to them.
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
//   [x] LCD ticker (time, date, local weather via WeatherKit) — RETIRED 2026-11-19
//   [x] Station persistence across launches (no auto-play)
//   [ ] Custom background image (PhotosPicker, user-defined, persisted)
//   [x] Sleep timer (30m, 1h, 2h, 4h)
//   [x] AirPlay 2 output picker (Settings; player card planned — sheet 041)
//   [x] Play/Pause/Skip/Stop controls
//   [x] Now Playing info on lock screen (free from MusicKit)
//   [x] Settings screen
//
// v1.1+ — Future Enhancements (raise iOS minimum as needed)
// ----------------------------------------------------------
//   [ ] Tally Matrix Clock leader/follower sync via CloudKit
//   [ ] iCloud sync for settings + background image across devices
//   [x] ShazamKit song recognition (requires NSMicrophoneUsageDescription)
//   [ ] Dark/light automatic icon switching (iOS 18+)
//   [ ] Additional color themes beyond ice blue
//   [x] Landscape mode — adaptive two-column, Fold-ready (2026-06-28)
//   [x] iPad support
//   [-] Widget for home screen — REMOVED on purpose 2026-06-28 (see above)
//   [x] iOS 27 native Music Picker — "Search Apple Music" in My Music (2026-06-28)
//   [x] Siri / Shortcuts App Intents — play station, transport, sleep timer (2026-06-28)
//   [ ] Easter egg (hidden interaction — tap title or idle screen)
//   [ ] Queue position persistence (resume exact track on relaunch)
//   [ ] Custom background image (z-ordering issue: image renders over UI — needs proper layer fix)
//   [ ] Background image persistence survives clean build (dev-only issue, works for App Store users)
//   [ ] Graceful error messages (no subscription, no network) — planned, sheet 002/003/035
//   [ ] CarPlay audio app — entitlement requested 2026-11-24, waiting on Apple
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
// Bundle ID: com.Tangerine.CryoTunesPlayer
// SKU: CryoTunesPlayer
// Category: Music
// URL: https://apps.apple.com/us/app/cryotunes-player/id6761222456
//
// Current Version: 4.0.1 (build = git commit count, 101 at 2026-11-24)
// Status: 3.0.1 approved 2026-10-31; 4.0.1 submission status ⚠️ verify in App Store Connect
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
//   genres, Billboard decade charts from 1958 to 2026, nature
//   sounds, focus frequencies, and ASMR white noise — or browse
//   your own music library with playlists, albums, and artists.
//
// What's New (v3.0):
//   - Landscape: two-column layout that uses the full screen (Fold-ready)
//   - Search Apple Music: pick from the full catalog right in My Music (iOS 27)
//   - Siri & Shortcuts: play a station, transport, and sleep timer hands-free
//   - Home Screen widget: play / pause / skip controls
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
//   v3.0 (2026-06-28) — Landscape, iOS 27 Music Picker, Siri/Shortcuts intents (widget removed same day); approved 2026-10-19
//   v3.0.1 (2026-10-19) — Duo layouts, mode-button fits; approved 2026-10-31
//   v4.0 (2026-11-19) — LCD + weather retired, album-art wallpaper, quadrant cards
//   v4.0.1 (2026-11-20) — Universal image, Shuffle fits
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
//   [ ] Bundle ID confirmed (com.Tangerine.CryoTunesPlayer)
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

// ============================================================
// CONTACT THE DEVELOPER — NEXT UPDATE (his standard for all apps, 2026-09-18): the feedback form must send ONLY the user's message + the app version. Remove device model, OS, storage, locale and any other diagnostics. His words: "i dont want personal information. i just want a pipeline to communicate with users."
// ============================================================
