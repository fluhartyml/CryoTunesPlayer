//
//  CryoTunes_PlayerUITests.swift
//  CryoTunes PlayerUITests
//
//  Created by Michael Fluharty on 3/26/26.
//
//  REM 2026-11-19 — the robots: drive the app through its accessibility labels (his rule: test
//  our apps through VoiceOver labels and the keyboard, not screenshots and clicks). These check
//  the wallpaper layout he approved in the Mockup: LCD and title gone, the player card's
//  controls, Card Position in Settings (with swap), and My Music taking over the Stations card.
//  They can't fold a Duo — folded poses are checked on his real Duo.
//

import XCTest

final class CryoTunes_PlayerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10), "Settings (cog) button missing")
        // Every test starts from the Mockup's default: player bottom right, Stations bottom left.
        setQuadrants(player: "br", stations: "bl")
    }

    // MARK: - Helpers

    private var isWide: Bool { app.windows.firstMatch.frame.width >= 700 }
    private var screen: CGRect { app.windows.firstMatch.frame }

    private func openSettings() {
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5), "Settings sheet didn't open")
    }

    private func closeSettings() {
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
    }

    /// Scrolls Settings until the element can be tapped, then taps it.
    private func tapInSettings(_ element: XCUIElement) {
        var tries = 0
        while !element.isHittable && tries < 8 { app.swipeUp(); tries += 1 }
        XCTAssertTrue(element.isHittable, "\(element) never came into view")
        element.tap()
    }

    private func setQuadrants(player: String, stations: String) {
        openSettings()
        tapInSettings(app.buttons["quad.player.\(player)"])
        tapInSettings(app.buttons["quad.stations.\(stations)"])
        XCTAssertTrue(app.buttons["quad.player.\(player)"].isSelected)
        XCTAssertTrue(app.buttons["quad.stations.\(stations)"].isSelected)
        closeSettings()
    }

    private var playerCard: XCUIElement { app.descendants(matching: .any)["playerCard"] }
    private var stationsCard: XCUIElement { app.descendants(matching: .any)["stationsCard"] }

    // MARK: - Tests

    /// The LCD, the weather and the title bar are gone; the player card holds every control,
    /// with the Sleep Timer buttons last and no small "Sleep" line.
    @MainActor
    func testPlayerCardHasEveryControlAndNoLCD() throws {
        XCTAssertTrue(playerCard.waitForExistence(timeout: 5), "player card missing")
        for label in ["Shuffle", "All", "One", "Like", "Skip", "Share", "Off", "30m", "1h", "2h", "4h", "Shazam", "Settings"] {
            XCTAssertTrue(app.buttons[label].exists, "button \(label) missing")
        }
        XCTAssertFalse(app.staticTexts["Player"].exists, "the old title bar is still showing")
        XCTAssertFalse(app.buttons["Sleep timer"].exists, "the small Sleep line is still showing")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '°F'")).firstMatch.exists,
                       "weather is still showing")
        // Sleep Timer last: its buttons sit below Like/Skip/Share.
        XCTAssertGreaterThan(app.buttons["30m"].frame.minY, app.buttons["Like"].frame.maxY)
        // Player card defaults to the bottom.
        XCTAssertGreaterThan(playerCard.frame.midY, screen.midY)
    }

    /// Card Position: choosing a spot moves the card; choosing the other card's spot swaps them.
    @MainActor
    func testCardPositionMovesAndSwaps() throws {
        if isWide {
            XCTAssertTrue(stationsCard.waitForExistence(timeout: 5), "Stations card missing on a wide screen")
            XCTAssertGreaterThan(playerCard.frame.midX, screen.midX, "player should start on the right")
            XCTAssertLessThan(stationsCard.frame.midX, screen.midX, "Stations should start on the left")

            // Player takes the Stations card's spot (bottom left) → they swap.
            openSettings()
            tapInSettings(app.buttons["quad.player.bl"])
            XCTAssertTrue(app.buttons["quad.stations.br"].isSelected, "Stations didn't swap to bottom right")
            closeSettings()
            XCTAssertLessThan(playerCard.frame.midX, screen.midX, "player didn't move left")
            XCTAssertGreaterThan(stationsCard.frame.midX, screen.midX, "Stations didn't move right")

            // Player to the top right.
            setQuadrants(player: "tr", stations: "br")
            XCTAssertLessThan(playerCard.frame.midY, stationsCard.frame.midY, "player didn't move to the top")
        } else {
            XCTAssertFalse(stationsCard.exists, "Stations card should wait behind the cog on a narrow screen")
            setQuadrants(player: "tl", stations: "bl")
            XCTAssertLessThan(playerCard.frame.midY, screen.midY, "player didn't move to the top half")
        }
        setQuadrants(player: "br", stations: "bl")
    }

    /// My Music takes over the Stations card with ‹ Back; Back returns to the stations.
    @MainActor
    func testMyMusicTakesOverTheCard() throws {
        try XCTSkipUnless(isWide, "the Stations card only shows on screens 700 points wide or more")
        XCTAssertTrue(stationsCard.waitForExistence(timeout: 5))
        XCTAssertTrue(stationsCard.staticTexts["STATIONS"].exists)
        let myMusic = stationsCard.buttons.matching(NSPredicate(format: "label CONTAINS 'My Music'")).firstMatch
        var tries = 0
        while !myMusic.isHittable && tries < 6 { stationsCard.swipeUp(); tries += 1 }
        myMusic.tap()
        XCTAssertTrue(stationsCard.buttons["Back"].waitForExistence(timeout: 5), "no ‹ Back after tapping My Music")
        XCTAssertTrue(stationsCard.staticTexts["MY MUSIC"].exists)
        XCTAssertFalse(stationsCard.staticTexts["STATIONS"].exists, "My Music didn't take over the whole card")
        stationsCard.buttons["Back"].tap()
        XCTAssertTrue(stationsCard.staticTexts["STATIONS"].waitForExistence(timeout: 5), "Back didn't return")
    }
}
