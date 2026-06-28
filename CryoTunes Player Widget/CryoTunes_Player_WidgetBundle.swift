//
//  CryoTunes_Player_WidgetBundle.swift
//  CryoTunes Player Widget
//
//  Created by Michael Fluharty on 6/28/26.
//

import WidgetKit
import SwiftUI

@main
struct CryoTunes_Player_WidgetBundle: WidgetBundle {
    var body: some Widget {
        CryoTunes_Player_Widget()
        CryoTunes_Player_WidgetControl()
        CryoTunes_Player_WidgetLiveActivity()
    }
}
