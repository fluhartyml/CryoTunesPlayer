//
//  Platform.swift
//  CryoTunes Player
//
//  REM: his word 11-18 16:1x: "yes fix the mac build". The app lists macosx as a
//  supported platform, but UIKit and MessageUI don't exist on the Mac, so the Mac
//  build failed. The few iPhone-only calls go through here, each with a Mac twin.
//

import SwiftUI
#if os(iOS)
import UIKit
import MessageUI
#else
import AppKit
#endif

enum Platform {
    /// "iOS 27.3" / "macOS Version 27.2 (Build …)" for feedback and failure reports.
    static var systemDescription: String {
        #if os(iOS)
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        #else
        "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
        #endif
    }

    /// iPhone needs a mail account for the in-app composer. The Mac hands the
    /// message to the default mail app instead, so it can always send.
    static var canSendMail: Bool {
        #if os(iOS)
        MFMailComposeViewController.canSendMail()
        #else
        true
        #endif
    }

    @MainActor static func open(_ url: URL) {
        #if os(iOS)
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
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// The navigation bar exists only on iPhone/iPad.
    func darkNavigationBar() -> some View {
        #if os(iOS)
        toolbarColorScheme(.dark, for: .navigationBar)
        #else
        self
        #endif
    }

    func materialNavigationBar() -> some View {
        #if os(iOS)
        toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        #else
        self
        #endif
    }
}
