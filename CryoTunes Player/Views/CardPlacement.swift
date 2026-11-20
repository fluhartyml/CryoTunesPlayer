//
//  CardPlacement.swift
//  CryoTunes Player
//
//  REM 2026-11-19 — where the two glass cards (player, Stations) sit on the screen.
//  His word, 11-19 18:2x: "i want the user to be amble to switch either side and i m thinking
//  quadrants they can shigt into either of the cards and the bottom right side card i want that
//  quadrant to include the colum under the clock". Then 18:5x: "use duo open as the guiding
//  config to try and make consistant with the other configurations" — ONE rule for every pose
//  (Apple's HIG for iPhone Duo: "Keep controls consistent across device poses").
//  Approved on every screen in the Mockup (his "i like them", 18:53).
//

import SwiftUI

/// One quarter of the screen. Stored by raw value in @AppStorage, so a listener's choice
/// survives relaunches and holds in every pose.
enum CardQuadrant: String, CaseIterable, Identifiable {
    case topLeft = "tl", topRight = "tr", bottomLeft = "bl", bottomRight = "br"

    var id: String { rawValue }
    var isTop: Bool { self == .topLeft || self == .topRight }
    var isLeft: Bool { self == .topLeft || self == .bottomLeft }

    /// Spoken and shown name: two words (his three-word rule for accessibility names).
    var label: String {
        switch self {
        case .topLeft: "Top left"
        case .topRight: "Top right"
        case .bottomLeft: "Bottom left"
        case .bottomRight: "Bottom right"
        }
    }

    /// AppStorage keys and defaults: player bottom right, Stations bottom left (the Mockup).
    static let playerKey = "cardQuadrant.player"
    static let stationsKey = "cardQuadrant.stations"
}

/// The rectangles for the cards, in the coordinates of the safe area.
///
/// REM — the rule, read straight from the approved Mockup (quadRect):
/// - 700 pt wide or more: the middle (the crease on an open Duo) splits left | right, the middle
///   splits top | bottom. Four quadrants.
/// - Narrower: left and right merge into one column; only top | bottom remain, and the Stations
///   card waits behind the cog (it is in Settings).
/// - Bottom right (and the bottom half on a narrow screen) runs to the screen's trailing edge,
///   taking the column under the clock on a Duo.
/// - Claude's call, not in the Mockup: when a quadrant is too short for the player card (an
///   iPhone turned sideways), each card takes its whole side, top to bottom.
struct CardLayout {
    let size: CGSize            // the safe area
    let trailingInset: CGFloat  // the Duo's status column (clock, Wi-Fi, battery)
    let fullWidth: CGFloat      // the whole screen, insets included
    let creaseMidX: CGFloat?    // open Duo, sideways: the crease runs top to bottom here
    let creaseMidY: CGFloat?    // open Duo, upright: the crease runs side to side here
    let topReserve: CGFloat     // room kept for Shazam + Settings when they sit at the top

    private let pad: CGFloat = 12
    static let minQuadrantHeight: CGFloat = 260

    var hasQuadrants: Bool { fullWidth >= 700 }
    private var tallEnough: Bool { (size.height - topReserve) / 2 - pad * 1.5 >= Self.minQuadrantHeight }

    func rect(for q: CardQuadrant) -> CGRect {
        let w = size.width, h = size.height
        let top = topReserve
        let midX = creaseMidX ?? w / 2
        let halfX: CGFloat = creaseMidX == nil ? pad / 2 : 12 + pad
        let midY = creaseMidY ?? top + (h - top) / 2
        let halfY: CGFloat = creaseMidY == nil ? pad / 2 : 12 + pad / 2

        var x: CGFloat, cw: CGFloat
        if hasQuadrants {
            if q.isLeft { x = pad; cw = midX - halfX - pad }
            else { x = midX + halfX; cw = w - pad - x }
        } else {
            x = pad; cw = w - 2 * pad
        }

        var y: CGFloat, ch: CGFloat
        if hasQuadrants && !tallEnough {
            y = top + pad; ch = h - pad - y
        } else if q.isTop {
            y = top + pad; ch = midY - halfY - y
        } else {
            y = midY + halfY; ch = h - pad - y
        }

        // Bottom right runs to the edge, under the clock column.
        // Not when a card takes the whole side: the column's top holds Shazam and Settings.
        if (q == .bottomRight && (tallEnough || !hasQuadrants)) || (!hasQuadrants && !q.isTop) {
            cw = w + trailingInset - pad - x
        }
        return CGRect(x: x, y: y, width: max(0, cw), height: max(0, ch))
    }
}
