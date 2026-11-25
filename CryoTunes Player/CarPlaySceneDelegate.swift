//
//  CarPlaySceneDelegate.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 11/25/26.
//

// REM: Review sheet line 032 — CarPlay. His word 2026-11-25 ~12:0x: "the car play was approved",
// REM: then "finish the cryotunes too". Apple granted the CarPlay audio entitlement, so the
// REM: Addendum §2 hold (no CarPlay API use before the grant) is lifted.
// REM: CarPlay audio apps are built only from Apple's templates: a list to choose from and
// REM: Apple's shared Now Playing screen. The stations are the same ones the phone shows, and
// REM: they play through the same shared player, so the phone and the car never disagree.
// REM: ApplicationMusicPlayer publishes now-playing info itself, so Now Playing fills in.

#if os(iOS) && canImport(CarPlay)
import CarPlay
import UIKit

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(makeRoot(), animated: false, completion: nil)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }

    /// One tab per station category, as on the phone. CarPlay allows a few tabs; the
    /// categories fit (Music, Apple Radio, Popular Hits, Sound Machine, Focus).
    private func makeRoot() -> CPTemplate {
        let tabs: [CPTemplate] = StationCategory.allCases.prefix(CPTabBarTemplate.maximumTabCount).map { category in
            let items = MusicStationOption.stations(for: category)
                .prefix(CPListTemplate.maximumItemCount)
                .map(makeItem)
            let list = CPListTemplate(title: category.rawValue,
                                      sections: [CPListSection(items: Array(items))])
            list.tabTitle = category.rawValue
            list.tabImage = UIImage(systemName: symbol(for: category))
            return list
        }
        return CPTabBarTemplate(templates: tabs)
    }

    private func makeItem(_ station: MusicStationOption) -> CPListItem {
        let item = CPListItem(text: station.displayName, detailText: nil)
        item.handler = { [weak self] _, completion in
            Task { @MainActor in
                await CryoPlayerHost.player.play(station: station)
                self?.showNowPlaying()
                completion()
            }
        }
        return item
    }

    private func showNowPlaying() {
        guard let controller = interfaceController,
              controller.topTemplate !== CPNowPlayingTemplate.shared else { return }
        controller.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
    }

    private func symbol(for category: StationCategory) -> String {
        switch category {
        case .music: "music.note"
        case .appleRadio: "dot.radiowaves.left.and.right"
        case .billboard: "chart.line.uptrend.xyaxis"
        case .nature: "leaf"
        case .focus: "brain.head.profile"
        }
    }
}
#endif
