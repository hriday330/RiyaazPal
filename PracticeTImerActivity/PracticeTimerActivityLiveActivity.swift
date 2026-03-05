//
//  PracticeTimerActivityLiveActivity.swift
//  PracticeTimerActivity
//
//  Created by Hriday Buddhdev on 2026-03-04.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PracticeTimerActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PracticeTimerActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(spacing: 6) {

                Text(context.attributes.title)
                    .font(.headline)

                Text(timerInterval: context.state.startTime...Date(), countsDown: false)
                    .font(.title)
                    .monospacedDigit()
            }

        } dynamicIsland: { context in
            DynamicIsland {

                DynamicIslandExpandedRegion(.center) {

                    VStack {

                        Text("Practice")
                            .font(.headline)
                        
                        Text(timerInterval: context.state.startTime...Date.distantFuture, countsDown: false)
                       
                    }
                }

            } compactLeading: {

                Image(systemName: "music.note")

            } compactTrailing: {

                Text(timerInterval: context.state.startTime...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
                    .font(.caption2)

            } minimal: {

                Image(systemName: "music.note")
            }
        }
    }
}

#Preview("Notification", as: .content, using: PracticeTimerActivityAttributes(title: "Practice Session")) {
   PracticeTimerActivityLiveActivity()
} contentStates: {
    PracticeTimerActivityAttributes.ContentState(
        startTime: Date().addingTimeInterval(-600)
    )
}
