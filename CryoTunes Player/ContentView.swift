//
//  ContentView.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import SwiftUI
import MusicKit
import ShazamKit

struct ContentView: View {
    @State private var playerManager = CryoPlayerHost.player
    // REM 2026-11-19 — the weather retired with the LCD. His word, 18:54: "weater and everything
    // to do with the lcd". No weather request, so no location ask either. WeatherManager.swift
    // and LCDTickerView.swift stay in the project, unused (his "rem line it if you want").
    @State private var dislikeManager = DislikeManager()
    @State private var playlistManager = PlaylistManager()
    @State private var favoriteManager = FavoriteManager()
    @State private var showSettings = false
    @State private var showAlbumView = false
    @State private var selectedAlbum: Album?
    @State private var shazamManager = ShazamManager()
    @State private var shazamLoadingAlbum = false
    @State private var showShazamNoMatchSheet = false
    @State private var stationFailureMonitor = StationFailureMonitor()
    @State private var reportForMail: StationReport?
    @State private var showingFailureMailComposer = false
    @State private var showSleepTimerSheet = false
    @State private var fullWidth: CGFloat = 0
    @State private var topInset: CGFloat = 0

    /// REM 2026-11-19 — the 11-18 side panel (Sleep Timer + Stations, build 87) is gone. In its
    /// place: two glass cards in quadrants (see CardPlacement.swift). The Sleep Timer moved into
    /// the player card, last (his word 18:37: "the sleep timer should be on the bottom under pop
    /// hits 1980 popular hits"); the station readout moved to the Stations card (18:38: "pop hits
    /// and popular hits is related more to the stations card"). The listener picks each card's
    /// quadrant in Settings; picking the other card's quadrant swaps them.
    @AppStorage(CardQuadrant.playerKey) private var playerQuadrantRaw = CardQuadrant.bottomRight.rawValue
    @AppStorage(CardQuadrant.stationsKey) private var stationsQuadrantRaw = CardQuadrant.bottomLeft.rawValue
    @State private var myMusicOpen = false
    private var playerQuadrant: CardQuadrant { CardQuadrant(rawValue: playerQuadrantRaw) ?? .bottomRight }
    private var stationsQuadrant: CardQuadrant { CardQuadrant(rawValue: stationsQuadrantRaw) ?? .bottomLeft }

    /// Shazam + Settings sit at the top trailing corner when no status column or strip holds
    /// them (a regular iPhone upright, an iPad). Before, they rode the title bar, which retired
    /// with the LCD.
    private var usesCornerButtons: Bool { !usesSideColumn && !usesTopStrip && !usesPhoneColumn }

    // Ice blue palette
    private let iceBlue = Color(red: 0.65, green: 0.82, blue: 0.95)
    private let iceDark = Color(red: 0.12, green: 0.18, blue: 0.28)
    private let iceGlow = Color(red: 0.45, green: 0.72, blue: 0.92)
    private let iceBorder = Color(red: 0.35, green: 0.55, blue: 0.75)
    private let iceAccent = Color(red: 0.5, green: 0.78, blue: 0.95)

    // Resolution-independent layout signal: split into two columns whenever the
    // available area is wider than it is tall (landscape phone, landscape iPad,
    // an unfolded Fold), and stack when taller than wide (any portrait).
    // Measured from real geometry, NOT size classes — size classes treat iPad
    // portrait and landscape identically, the exact case the iPad mini hits.
    // Aspect ratio is the true signal.
    @State private var isWide = false

    // iPhone Duo, open or closed: the status icons (clock, Wi-Fi, battery)
    // sit in a column down the right edge. Shazam and Settings move into that
    // column, under the status icons. A hinge (UIHingeInteraction, iOS 27.1)
    // is what marks a Duo; the trailing inset gives the column width.
    // Duo upright (status bar across the top): they sit in the top strip,
    // just left of the clock.
    // Duo partly open with the fold across the middle (laptop pose): art on
    // the top half, the track box on the fold, controls on the bottom half.
    // Regular iPhone sideways: they move to the right-edge column — gear
    // above the notch and Shazam below it when the notch is on the right,
    // stacked at the top when the right edge is clear.
    @State private var hasHinge = false
    /// REM 2026-11-19 21:2x — his word: "jesus, why cant it only change iphone regular / iphone
    /// duo/ ipad/ mac?" Builds 90 (card fits its contents) and 91 (two-layer art) are for a
    /// REGULAR iPhone only. The Duo (it has a hinge), iPad, and Mac (it runs the iPad app, idiom
    /// .pad) keep exactly what build 89 did. Each device type changes only when he names it.
    private var isRegularIPhone: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone && !hasHinge
        #else
        false
        #endif
    }
    @State private var hingePartlyOpen = false
    @State private var hingeAngle: CGFloat?
    /// His word 11-18: reflect the art on the lower screen when the Duo is "opened 90degrees or
    /// less (accute angle)". No angle reported (unknown) → reflect whenever it's partly open.
    private var reflectsArt: Bool { usesFoldLayout && (hingeAngle.map { $0 <= .pi / 2 + 0.05 } ?? true) }
    @State private var sideColumn: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    @State private var notchOnRight = false
    private var usesSideColumn: Bool { hasHinge && sideColumn >= 44 }
    private var usesTopStrip: Bool { hasHinge && !usesSideColumn }
    private var usesPhoneColumn: Bool { !hasHinge && isWide && sideColumn >= 44 }
    private var usesFoldLayout: Bool { hasHinge && hingePartlyOpen && !isWide }
    /// REM 2026-11-18 — laptop pose (Duo partly open) floods the top half and mirrors the art onto
    /// the lower screen — his note 11-18 7:38 AM: "It should be full screen with reflections on
    /// the keyboard (lower half)". Kept as-is this round (floodArtLayer); every other pose uses
    /// wallpaperLayer since 11-19. (The old half-height flood for upright screens retired then.)

    // Interface .landscapeLeft = home side on the left, so the notch (top of
    // the phone) is on the right — UIOrientation.h.
    private func readNotchSide() {
        #if os(iOS)
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        notchOnRight = scene?.effectiveGeometry.interfaceOrientation == .landscapeLeft
        #endif
    }

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // REM 2026-11-19 — the album art is the wallpaper: one layer, the whole screen,
            // cropped at the edges, top kept in view. His words: "that pink floys album art should
            // have been full screen", "that album art should be ancored to the top", and his
            // compromise (18:20) "if you cant move the control card i think how my screen is now
            // is the compromise" = Fill, crop the edges. Laptop pose keeps its fold layout and
            // reflection this round (the plan, step 7).
            if usesFoldLayout { floodArtLayer } else if isRegularIPhone { wallpaperLayer } else { singleArtLayer }

            HingeReader(hasHinge: $hasHinge, partlyOpen: $hingePartlyOpen, angle: $hingeAngle)
                .frame(width: 0, height: 0)

            // REM 2026-11-19 — the LCD, the weather and the "CryoTunes vX (N) Player" title bar
            // are retired. His word 9:59 AM card: "The lcd needs to be retired". The version and
            // build number still show in Settings → About.
            if usesFoldLayout {
                foldBody
                    .padding(.bottom, 20)
            } else {
                cardsLayer
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        isWide = geo.size.width > geo.size.height
                        sideColumn = geo.safeAreaInsets.trailing
                        topInset = geo.safeAreaInsets.top
                        fullWidth = geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing
                        screenHeight = geo.frame(in: .global).maxY + geo.safeAreaInsets.bottom
                        readNotchSide()
                    }
                    .onChange(of: geo.size) { _, newSize in
                        isWide = newSize.width > newSize.height
                        fullWidth = newSize.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing
                        screenHeight = geo.frame(in: .global).maxY + geo.safeAreaInsets.bottom
                        readNotchSide()
                    }
                    .onChange(of: geo.safeAreaInsets) { _, newInsets in
                        sideColumn = newInsets.trailing
                        topInset = newInsets.top
                        fullWidth = geo.size.width + newInsets.leading + newInsets.trailing
                    }
            }
        )
        .sheet(isPresented: $showSleepTimerSheet) {
            VStack(alignment: .leading, spacing: 14) {
                Text("SLEEP TIMER")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(iceBorder)
                    .tracking(1.5)
                sleepTimerButtons
                timerCountdown
            }
            .padding(20)
            .presentationDetents([.height(190)])
            .presentationBackground(Color(red: 0.06, green: 0.09, blue: 0.16))
        }
        .overlay(alignment: .topTrailing) {
            if usesSideColumn {
                VStack(spacing: 12) {
                    shazamButton
                    settingsButton
                }
                .frame(width: sideColumn)
                .padding(.top, 72)
                .ignoresSafeArea(edges: .trailing)
            } else if usesTopStrip {
                // Measured on the Duo simulator, open: the clock starts about
                // 130 pt in from the right edge; the status row is centred
                // about 44 pt down.
                HStack(spacing: 8) {
                    shazamButton
                    settingsButton
                }
                .padding(.trailing, 140)
                .padding(.top, 22)
                .ignoresSafeArea(edges: [.top, .trailing])
            } else if usesPhoneColumn {
                VStack(spacing: 12) {
                    if notchOnRight {
                        settingsButton
                        Spacer()
                        shazamButton
                    } else {
                        shazamButton
                        settingsButton
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
                .frame(width: sideColumn)
                .frame(maxHeight: .infinity)
                .ignoresSafeArea(edges: .trailing)
            } else {
                HStack(spacing: 8) {
                    shazamButton
                    settingsButton
                }
                .padding(.trailing, 12)
                .padding(.top, 4)
            }
        }
        .overlay(alignment: .center) {
            if shazamLoadingAlbum {
                shazamLoadingOverlay
            }
        }
        .onChange(of: shazamManager.matchedTitle) { _, newTitle in
            guard !newTitle.isEmpty else { return }
            shazamLoadingAlbum = true
            openShazamAlbum()
        }
        .onChange(of: shazamManager.noMatch) { _, newNoMatch in
            guard newNoMatch else { return }
            shazamManager.noMatch = false
            showShazamNoMatchSheet = true
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(playerManager: playerManager, dislikeManager: dislikeManager, stationFailureMonitor: stationFailureMonitor)
        }
        .alert("Couldn't load this station", isPresented: Binding(
            get: { stationFailureMonitor.pendingReport != nil },
            set: { isShowing in
                if !isShowing { stationFailureMonitor.dismiss() }
            }
        )) {
            Button("Send Report") {
                #if os(macOS)
                // REM: Mac — the mail app composes it; no in-app sheet.
                if let report = stationFailureMonitor.pendingReport {
                    Platform.composeMail(to: "michael.fluharty@mac.com",
                                         subject: report.emailSubject,
                                         body: report.emailBody)
                }
                stationFailureMonitor.dismiss()
                #else
                reportForMail = stationFailureMonitor.pendingReport
                stationFailureMonitor.dismiss()
                showingFailureMailComposer = true
                #endif
            }
            Button("Not Now", role: .cancel) {
                stationFailureMonitor.dismiss()
            }
        } message: {
            Text("Want to send a report so this station can be fixed?")
        }
        #if os(iOS)
        .sheet(isPresented: $showingFailureMailComposer, onDismiss: {
            reportForMail = nil
        }) {
            if let report = reportForMail {
                MailComposeView(
                    subject: report.emailSubject,
                    body: report.emailBody,
                    recipient: "michael.fluharty@mac.com"
                )
            }
        }
        #endif
        .sheet(isPresented: $showAlbumView) {
            if let album = selectedAlbum {
                AlbumDetailView(album: album, playlistManager: playlistManager)
            }
        }
        .sheet(isPresented: $showShazamNoMatchSheet) {
            ShazamNoMatchSheet()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            shazamManager.playlistManager = playlistManager
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.15),
                Color(red: 0.1, green: 0.15, blue: 0.25),
                Color(red: 0.05, green: 0.08, blue: 0.15)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Shazam + Settings

    private var shazamButton: some View {
        Button {
            Task { await shazamManager.startListening() }
        } label: {
            Image(systemName: shazamManager.isListening ? "waveform" : "shazam.logo.fill")
                .font(.system(size: 28))
                .foregroundStyle(shazamManager.isListening ? iceGlow : iceBlue)
                .symbolEffect(.pulse, isActive: shazamManager.isListening)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Shazam")
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 28))
                .foregroundStyle(iceBlue)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Settings")
    }

    // MARK: - Cards (quadrants)

    /// REM 2026-11-19 — one rule for every pose, Duo open as the guide (his word 18:5x). The
    /// rectangles come from CardLayout; each card fills its quadrant and fits its contents to it
    /// (his 11-14 rule: "youre supposed to use contengent sizing so enerything fits naturally").
    private var cardsLayer: some View {
        GeometryReader { geo in
            let layout = CardLayout(
                size: geo.size,
                trailingInset: geo.safeAreaInsets.trailing > 0 ? geo.safeAreaInsets.trailing : sideColumn,
                fullWidth: fullWidth,
                creaseMidX: (hasHinge && isWide) ? fullWidth / 2 - geo.safeAreaInsets.leading : nil,
                creaseMidY: (hasHinge && !isWide && fullWidth > 600) ? screenHeight / 2 - topInset : nil,
                topReserve: usesCornerButtons ? 52 : 0
            )
            let p = layout.rect(for: playerQuadrant)
            ZStack(alignment: .topLeading) {
                if layout.hasQuadrants {
                    let s = layout.rect(for: stationsQuadrant)
                    stationsCard
                        .frame(width: s.width, height: s.height)
                        .offset(x: s.minX, y: s.minY)
                }
                if layout.hasQuadrants || !isRegularIPhone {
                    playerCard(fillsQuadrant: true)
                        .frame(width: p.width, height: p.height)
                        .offset(x: p.minX, y: p.minY)
                } else {
                    // REM 2026-11-19 20:1x — his word: "on the iphone cryotunes player the no track
                    // player card is a smaii amount too small causing the sleep timer to make the
                    // card scroll". A narrow screen has only the one card, so it no longer stops
                    // at the half: it hugs its contents and grows from its own edge (bottom card
                    // grows up, top card grows down) into the whole column, scrolling only if
                    // even that is too short. Contingent sizing, his 11-14 rule.
                    let top = layout.rect(for: .topLeft).minY
                    let bottom = layout.rect(for: .bottomLeft).maxY
                    playerCard(fillsQuadrant: false)
                        .frame(width: p.width, height: bottom - top,
                               alignment: playerQuadrant.isTop ? .top : .bottom)
                        .offset(x: p.minX, y: top)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }

    /// Track, time bar, transport, Shuffle/All/One, Like/Skip/Share, then the Sleep Timer last.
    /// REM 2026-11-19 — the small "Sleep" line is gone (his "ooh yeah", 18:39): the timer
    /// buttons are right there. Full spacing first; tighter if the quadrant is short; it scrolls
    /// only if even that can't fit.
    /// `fillsQuadrant: false` (narrow screens) — the card is as tall as what it shows, no taller.
    private func playerCard(fillsQuadrant: Bool) -> some View {
        ViewThatFits(in: .vertical) {
            playerCardContents(spacing: 12)
            playerCardContents(spacing: 6)
            ScrollView { playerCardContents(spacing: 6) }
        }
        .frame(maxWidth: .infinity, maxHeight: fillsQuadrant ? .infinity : nil)
        .glassEffect(.regular.tint(Color.black.opacity(0.35)), in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("playerCard")
    }

    private func playerCardContents(spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            trackInfoView
            progressBar
                .padding(.horizontal, 24)
            transportControls
            sleepTimerButtons
                .padding(.horizontal, 16)
        }
        .padding(.vertical, spacing + 4)
        .frame(maxWidth: .infinity)
    }

    /// Station readout on top ("Pop Hits: 1980 / POPULAR HITS"), the station list scrolling
    /// below it. My Music takes over the whole card with ‹ Back.
    private var stationsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !myMusicOpen {
                Text("STATIONS")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(iceBorder)
                    .tracking(1.5)
                stationDisplay
                    .frame(maxWidth: .infinity)
            }
            ScrollView {
                CryoStationPicker(
                    player: playerManager,
                    stationFailureMonitor: stationFailureMonitor,
                    tint: iceBlue,
                    accent: iceAccent,
                    border: iceBorder,
                    myMusicTakeover: $myMusicOpen
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .glassEffect(.regular.tint(Color.black.opacity(0.35)), in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stationsCard")
    }

    // Duo partly open, fold across the middle of the screen: art above the
    // fold, the track box centred on it, the controls below it.
    private var foldBody: some View {
        GeometryReader { geo in
            let fold = screenHeight / 2 - geo.frame(in: .global).minY
            ZStack(alignment: .top) {
                // REM 2026-11-18 — the art is floodArtLayer now (top screen + reflection below).
                trackInfoView
                    .position(x: geo.size.width / 2, y: fold)

                VStack(spacing: 0) {
                    progressBar
                        .padding(.horizontal, 32)
                    Spacer().frame(height: 8)
                    timerDisplay
                    Spacer().frame(height: 12)
                    transportControls
                    Spacer().frame(height: 20)
                    stationDisplay
                }
                .padding(.top, max(0, fold + 44))
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    // Album art with its long-press context menu.
    private var albumArtSection: some View {
        albumArtView
            .contextMenu { albumMenuItems }
    }

    /// The album art's long-press menu — shared by the framed art and the flooded art.
    @ViewBuilder private var albumMenuItems: some View {
                if let entry = ApplicationMusicPlayer.shared.queue.currentEntry,
                   case let .song(song) = entry.item {
                    Button {
                        openAlbumInApp(for: song)
                    } label: {
                        Label("Open Album", systemImage: "music.note.list")
                    }

                    Button {
                        addAlbumToLibrary(for: song)
                    } label: {
                        Label("Add Album to Library", systemImage: "plus.rectangle.on.folder")
                    }

                    Button {
                        playAlbum(for: song)
                    } label: {
                        Label("Play This Album", systemImage: "play.rectangle")
                    }

                    Button {
                        openAlbumInStore(for: song)
                    } label: {
                        Label("Open in iTunes Store", systemImage: "arrow.up.forward.app")
                    }

                    if let url = song.url {
                        ShareLink(item: url) {
                            Label("Share Song", systemImage: "square.and.arrow.up")
                        }
                    }
                }
    }

    /// REM 2026-11-18 — the flooded art: full width, top half of the screen, under the status
    /// bar. A dark fade at the top keeps the ticker readable over any cover; a fade at the bottom
    /// melts it into the background. Long-press keeps the album menu.
    private var floodArtLayer: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height * 0.5
            ZStack(alignment: .top) {
            if reflectsArt {
                // The lower screen: the art flipped like a reflection on a glossy desk, blurred and
                // dimmed so the controls on it stay readable, fading out toward the bottom edge.
                floodArt(width: w, height: h)
                    .frame(width: w, height: h)
                    .clipped()
                    .scaleEffect(x: 1, y: -1)
                    .blur(radius: 18)
                    .opacity(0.45)
                    .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                    .offset(y: h)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            floodArt(width: w, height: h)
                .frame(width: w, height: h)
                .clipped()
                .overlay(alignment: .top) {
                    LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 160)
                }
                .overlay(alignment: .bottom) {
                    // Laptop pose: no fade — the art meets its reflection at the fold.
                    LinearGradient(colors: [.clear, Color(red: 0.08, green: 0.12, blue: 0.2)], startPoint: .top, endPoint: .bottom)
                        .frame(height: usesFoldLayout ? 0 : 120)
                }
                .contentShape(Rectangle())
                .contextMenu { albumMenuItems }
                .accessibilityLabel("Album art")
            }
        }
        // Whole screen, so "half" is the Duo's fold line in laptop pose.
        .ignoresSafeArea()
    }

    /// REM 2026-11-19 — the wallpaper: one square cover, as big as the screen's longer side,
    /// centered left to right with its TOP at the top of the screen, cropped at the edges.
    /// Replaces wideArtLayer (half-screen art + mirrored glow, build 86) and the half-height
    /// flood for upright screens (build 85). His word: "that album art should be ancored to the
    /// top"; his pick in the Mockup: "Fill, crop the edges". A dark fade under the status bar
    /// keeps the clock and the buttons readable over any cover. Long-press keeps the album menu.
    ///
    /// REM 2026-11-19 21:3x — now two layers. His word: "the album art can be fit botom to top
    /// onn the back most layer and on the mid layer it the album art fit to the width ancored to
    /// the top of the screen swipes may not be needed" … "yes blur the back layer and build it".
    /// - Back: the cover filling the screen bottom to top, blurred (and dimmed a touch so the
    ///   sharp cover stands off it).
    /// - Middle: the whole cover, sharp, as wide as the screen, top at the top of the screen. On
    ///   an iPhone upright it ends above the player card, so nothing covers it.
    /// - Claude's call: on a screen wider than tall, a width-fit square would run off the bottom,
    ///   so the middle cover is capped at the screen's height (the whole cover still shows).
    /// The swipe-away cards are parked in git stash, not deleted.
    private var wallpaperLayer: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let cover = min(w, h)
            ZStack(alignment: .top) {
                floodArt(width: w, height: h)
                    .frame(width: w, height: h)
                    .clipped()
                    .blur(radius: 30, opaque: true)
                    .overlay(Color.black.opacity(0.2))
                floodArt(width: cover, height: cover)
                    .frame(width: cover, height: cover)
                    .clipped()
                    .shadow(color: .black.opacity(0.5), radius: 16, y: 6)
            }
            .frame(width: w, height: h, alignment: .top)
            .clipped()
            .overlay(alignment: .top) {
                    LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 140)
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .contextMenu { albumMenuItems }
                .accessibilityLabel("Album art")
        }
        .ignoresSafeArea()
    }

    /// Build 89's wallpaper, unchanged: one cover, Fill, top anchored, edges cropped.
    /// Duo (open, closed, upright), iPad and Mac keep this (his 21:2x word above).
    private var singleArtLayer: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            floodArt(width: w, height: h)
                .frame(width: w, height: h, alignment: .top)
                .clipped()
                .overlay(alignment: .top) {
                    LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 140)
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .contextMenu { albumMenuItems }
                .accessibilityLabel("Album art")
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func floodArt(width w: CGFloat, height h: CGFloat) -> some View {
        let side = max(w, h)
        if let artwork = playerManager.currentArtwork {
            ArtworkImage(artwork, width: side, height: side)
        } else {
            // REM: his TestFlight note 11-18 7:43 AM: "The blank album art should be a picture".
            // App icons can't be loaded by name (UIImage(named: "AppIcon") is nil), so use the
            // CryoTunesIcon image set: the same treble-clef art as the app icon.
            Image("CryoTunesIcon").resizable().scaledToFill().frame(width: side, height: side)
        }
    }


    // MARK: - Album Art

    private var albumArtView: some View {
        ZStack {
            // Bevel frame
            RoundedRectangle(cornerRadius: 8)
                .fill(iceDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                colors: [iceBorder.opacity(0.8), iceBorder.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            if let artwork = playerManager.currentArtwork {
                // Render the MusicKit Artwork directly via ArtworkImage (the supported
                // path). The old entry.artwork.url() + AsyncImage route returns a
                // musickit:// URL that AsyncImage can't load on the iOS 27 beta.
                GeometryReader { geo in
                    ArtworkImage(artwork,
                                 width: max(geo.size.width - 8, 0),
                                 height: max(geo.size.height - 8, 0))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            } else {
                artPlaceholder
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private var artPlaceholder: some View {
        // REM: his TestFlight note 11-18: "The blank album art should be a picture" —
        // the CryoTunesIcon art (the app icon's treble clef), not a note glyph.
        Image("CryoTunesIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(4)
    }

    // MARK: - Track Info

    private var trackInfoView: some View {
        VStack(spacing: 4) {
            // Retro LCD-style display
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(iceBorder.opacity(0.3), lineWidth: 1)
                    )

                VStack(spacing: 2) {
                    Text(playerManager.currentSongTitle.isEmpty ? "No Track" : playerManager.currentSongTitle)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                        // REM 2026-11-19 — the title wraps (two lines) instead of ending in "…";
                        // his 10:06 card showed it cut off. The plan, step 3.
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: iceGlow.opacity(0.3), radius: 2)

                    Text(playerManager.currentArtistName.isEmpty ? "---" : playerManager.currentArtistName)
                        .font(.system(size: 18, weight: .regular, design: .monospaced))
                        .foregroundStyle(iceAccent.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(minHeight: 56)
            // The box's shape is greedy; keep it to its text so it can't swell to fill the card.
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let elapsed = playerManager.playbackTime
        let duration = playerManager.trackDuration
        let remaining = max(0, duration - elapsed)
        let progress = duration > 0 ? elapsed / duration : 0

        return VStack(spacing: 4) {
            // Progress line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(iceBorder.opacity(0.2))
                        .frame(height: 3)

                    // Elapsed fill
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(iceAccent.opacity(0.6))
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)

            // Time labels
            HStack {
                Text(formatTime(elapsed))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceAccent.opacity(0.6))

                Spacer()

                Text("-\(formatTime(remaining)) / \(formatTime(duration))")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceAccent.opacity(0.6))
            }
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Album Actions

    private func openAlbumInApp(for song: Song) {
        Task {
            do {
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first {
                    let detailedAlbum = try await album.with([.tracks])
                    await MainActor.run {
                        selectedAlbum = detailedAlbum
                        showAlbumView = true
                    }
                }
            } catch {
                print("Open album error: \(error)")
            }
        }
    }

    private func openShazamAlbum() {
        guard let appleMusicID = shazamManager.matchedSong?.appleMusicID else {
            presentShazamNoMatch()
            return
        }
        Task {
            do {
                let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(appleMusicID))
                let response = try await request.response()
                guard let song = response.items.first else {
                    await MainActor.run { presentShazamNoMatch() }
                    return
                }
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first {
                    let detailedAlbum = try await album.with([.tracks])
                    await MainActor.run {
                        shazamLoadingAlbum = false
                        shazamManager.matchedTitle = ""
                        shazamManager.matchedArtist = ""
                        shazamManager.addedToLibrary = false
                        selectedAlbum = detailedAlbum
                        showAlbumView = true
                    }
                } else {
                    await MainActor.run { presentShazamNoMatch() }
                }
            } catch {
                print("Shazam album error: \(error)")
                await MainActor.run { presentShazamNoMatch() }
            }
        }
    }

    private func presentShazamNoMatch() {
        shazamLoadingAlbum = false
        shazamManager.matchedTitle = ""
        shazamManager.matchedArtist = ""
        shazamManager.addedToLibrary = false
        showShazamNoMatchSheet = true
    }

    private func addAlbumToLibrary(for song: Song) {
        Task {
            do {
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first {
                    try await PlaylistManager.libraryAddAlbum(album)
                    let detailedAlbum = try await album.with([.tracks])
                    await playlistManager.addAlbumPlaylist(detailedAlbum)
                }
            } catch {
                print("Add album error: \(error)")
            }
        }
    }

    private func playAlbum(for song: Song) {
        Task {
            do {
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first {
                    let detailedAlbum = try await album.with([.tracks])
                    await playlistManager.addAlbumPlaylist(detailedAlbum)
                    ApplicationMusicPlayer.shared.queue = .init(for: detailedAlbum.tracks ?? [])
                    try await ApplicationMusicPlayer.shared.play()
                }
            } catch {
                print("Play album error: \(error)")
            }
        }
    }

    private func openAlbumInStore(for song: Song) {
        Task {
            do {
                let detailedSong = try await song.with([.albums])
                if let album = detailedSong.albums?.first, let url = album.url {
                    await MainActor.run {
                        Platform.open(url)
                    }
                }
            } catch {
                print("Open in iTunes Store error: \(error)")
            }
        }
    }

    // MARK: - Timer Display

    /// REM 2026-11-18 — the moon on the player opens the sleep timer buttons (Off · 30m · 1h ·
    /// 2h · 4h), so it no longer takes a trip into Settings. Dim "Sleep" when no timer runs.
    private var timerDisplay: some View {
        Button { showSleepTimerSheet = true } label: {
            timerCountdown
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sleep timer")
    }

    private var timerCountdown: some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 18))
            Text(playerManager.sleepTimerRemaining.isEmpty ? "Sleep" : playerManager.sleepTimerRemaining)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(iceAccent.opacity(playerManager.sleepTimerRemaining.isEmpty ? 0.4 : 0.7))
        .frame(height: 24)
    }

    private var sleepTimerButtons: some View {
        CryoSleepTimerPicker(
            player: playerManager,
            tint: iceBlue,
            accent: iceAccent,
            dark: iceDark,
            border: iceBorder
        )
    }

    // MARK: - Transport Controls

    private var transportControls: some View {
        CryoTransportControls(
            player: playerManager,
            dislikeManager: dislikeManager,
            playlistManager: playlistManager,
            favoriteManager: favoriteManager,
            tint: iceBlue,
            accent: iceAccent,
            dark: iceDark,
            border: iceBorder,
            glow: iceGlow
        )
    }

    private func retroButton(icon: String, size: CGFloat, prominent: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            iceDark.opacity(0.8),
                            Color(red: 0.08, green: 0.12, blue: 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            LinearGradient(
                                colors: [iceBorder.opacity(0.6), iceBorder.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(prominent ? iceBlue : iceAccent.opacity(0.8))
                .shadow(color: prominent ? iceGlow.opacity(0.4) : .clear, radius: 3)
        }
        .frame(width: prominent ? 64 : 52, height: prominent ? 52 : 44)
    }

    // MARK: - Station Display

    private var stationDisplay: some View {
        VStack(spacing: 4) {
            if playerManager.currentStation != .none {
                Text(playerManager.nowPlayingTitle)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(iceAccent.opacity(0.5))
                    .lineLimit(1)

                Text(playerManager.currentStation.rawValue)
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundStyle(iceBorder.opacity(0.5))

                Text(playerManager.currentStation.category.rawValue.uppercased())
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundStyle(iceBorder.opacity(0.3))
            }
        }
    }
    // MARK: - Shazam Overlays

    private var shazamLoadingOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "shazam.logo.fill")
                .font(.system(size: 32))
                .foregroundStyle(iceAccent)
                .symbolEffect(.pulse, options: .repeating)

            Text("Shazam match — loading album…")
                .font(.system(size: 18, design: .monospaced))
                .foregroundStyle(iceBlue)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iceDark.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(iceBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: iceGlow.opacity(0.2), radius: 10)
        .transition(.opacity)
    }

}

#Preview {
    ContentView()
}

struct ShazamNoMatchSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let iceBlue = Color(red: 0.65, green: 0.82, blue: 0.95)
    private let iceAccent = Color(red: 0.5, green: 0.78, blue: 0.95)
    private let iceBorder = Color(red: 0.35, green: 0.55, blue: 0.75)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image("CryoTunesIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 240, height: 240)
                        .cornerRadius(12)
                        .shadow(color: iceAccent.opacity(0.3), radius: 12)

                    Text("No Match Found")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(iceBlue)
                        .multilineTextAlignment(.center)

                    Text("Shazam couldn't identify this song.")
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundStyle(iceBlue.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.25),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .navigationTitle("Album")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(iceAccent)
                }
            }
            .materialNavigationBar()
        }
    }
}

// MARK: - Hinge (iPhone Duo)

// Reports whether the device has a hinge (an iPhone Duo), and whether it
// is partly open. Uses UIHingeInteraction, new in iOS 27.1; on 27.0 or a
// phone without a hinge both stay false.
#if os(iOS)
struct HingeReader: UIViewRepresentable {
    @Binding var hasHinge: Bool
    @Binding var partlyOpen: Bool
    /// REM 2026-11-18 — hinge angle in radians (UIHinge.angle). The SDK header gives no range;
    /// Claude's assumption, NOT verified: 0 = closed, π/2 = an L, π = flat. Check on his Duo.
    var angle: Binding<CGFloat?>? = nil

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        if #available(iOS 27.1, *) {
            let hinged = $hasHinge
            let partly = $partlyOpen
            let ang = angle
            view.addInteraction(UIHingeInteraction { _, update in
                hinged.wrappedValue = update.hinge != nil
                partly.wrappedValue = update.hinge?.status == .partiallyOpen
                ang?.wrappedValue = update.hinge?.angle
            })
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#else
// REM: Mac twin — a Mac has no hinge, so hasHinge / partlyOpen stay false.
struct HingeReader: View {
    @Binding var hasHinge: Bool
    @Binding var partlyOpen: Bool
    var angle: Binding<CGFloat?>? = nil

    var body: some View { Color.clear.frame(width: 0, height: 0) }
}
#endif
