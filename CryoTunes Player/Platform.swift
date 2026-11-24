//
//  Platform.swift
//  CryoTunes Player
//
//  REM: his word 11-18 16:1x: "yes fix the mac build". The app lists macosx as a
//  supported platform, but UIKit and MessageUI don't exist on the Mac, so the Mac
//  build failed. The few iPhone-only calls go through here, each with a Mac twin.
//

import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
import MessageUI
#else
import AppKit
#endif

enum Platform {
    /// REM: review sheet 028 (his "okay lock it" 2026-11-24): the contact address
    /// lives in ONE place. It was typed in five.
    static let contactEmail = "michael.fluharty@mac.com"

    /// iPhone needs a mail account for the in-app composer. The Mac hands the
    /// message to the default mail app instead, so it can always send.
    static var canSendMail: Bool {
        #if os(iOS) || os(visionOS)
        MFMailComposeViewController.canSendMail()
        #else
        true
        #endif
    }

    @MainActor static func open(_ url: URL) {
        #if os(iOS) || os(visionOS)
        UIApplication.shared.open(url)
        #else
        NSWorkspace.shared.open(url)
        #endif
    }

    /// REM: Mac path for mail — a mailto: link opens a filled-in message in the
    /// user's mail app, where they press Send.
    @MainActor static func composeMail(to recipient: String, subject: String, body: String) {
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = recipient
        parts.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        if let url = parts.url { open(url) }
    }
}

extension View {
    /// Small centered title on iPhone; the Mac has no inline title mode.
    func inlineNavigationTitle() -> some View {
        #if os(iOS) || os(visionOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// The navigation bar exists only on iPhone/iPad.
    func darkNavigationBar() -> some View {
        #if os(iOS) || os(visionOS)
        toolbarColorScheme(.dark, for: .navigationBar)
        #else
        self
        #endif
    }

    /// REM: review 018 (2026-11-24): Liquid Glass (glassEffect) is unavailable on visionOS;
    /// REM: Vision Pro's own glass is glassBackgroundEffect. Same card, each platform's glass.
    @ViewBuilder func cardGlass() -> some View {
        #if os(visionOS)
        glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 24))
        #else
        glassEffect(.regular.tint(Color.black.opacity(0.35)), in: RoundedRectangle(cornerRadius: 24))
        #endif
    }

    func materialNavigationBar() -> some View {
        #if os(iOS) || os(visionOS)
        toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        #else
        self
        #endif
    }
}

// MARK: - Scaled fonts (review 043)

// REM: review 043 (2026-11-24, his "okay lock it") — every font in the app used a fixed
// REM: .system(size:), so 18 pt never grew for a listener who sets Larger Text. Each view that
// REM: sets fonts now holds ONE multiplier, @ScaledMetric(relativeTo: .body) var textScale = 1,
// REM: and writes .font(.system(size: 18 * textScale, ...)): 18 pt at the default text size,
// REM: growing with Dynamic Type (his 11-04: "18 point rule is my personal assistive setting" —
// REM: the listener's setting wins).
// REM: ⚠️ DO NOT go back to a per-call ViewModifier holding its own @ScaledMetric. Tried in
// REM: build 121's first pass: ~56 extra modifier layers overflowed the main-thread stack while
// REM: SwiftUI built the player (EXC_BAD_ACCESS, stack guard) and the app crashed at launch.
