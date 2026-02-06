//
//  SessionTypePicker.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-06.
//

import Foundation
import SwiftUI

struct SessionTypePicker: View {
    @Binding var sessionType: SessionType

    var body: some View {
        Picker("Session Type", selection: $sessionType) {
            Text("Practice").tag(SessionType.practice)
            Text("Concert").tag(SessionType.concert)
        }
        .pickerStyle(.segmented)
    }
}
