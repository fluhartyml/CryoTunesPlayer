//
//  CryoTunes_Player_WidgetLiveActivity.swift
//  CryoTunes Player Widget
//
//  Created by Michael Fluharty on 6/28/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CryoTunes_Player_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CryoTunes_Player_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CryoTunes_Player_WidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension CryoTunes_Player_WidgetAttributes {
    fileprivate static var preview: CryoTunes_Player_WidgetAttributes {
        CryoTunes_Player_WidgetAttributes(name: "World")
    }
}

extension CryoTunes_Player_WidgetAttributes.ContentState {
    fileprivate static var smiley: CryoTunes_Player_WidgetAttributes.ContentState {
        CryoTunes_Player_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CryoTunes_Player_WidgetAttributes.ContentState {
         CryoTunes_Player_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CryoTunes_Player_WidgetAttributes.preview) {
   CryoTunes_Player_WidgetLiveActivity()
} contentStates: {
    CryoTunes_Player_WidgetAttributes.ContentState.smiley
    CryoTunes_Player_WidgetAttributes.ContentState.starEyes
}
