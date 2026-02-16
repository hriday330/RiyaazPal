//
//  PracticeTimelineTypeEmptyState.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-15.
//

import Foundation
import SwiftUI

struct PracticeTimelineTypeEmptyState: View {
    let filter: SessionTypeFilter

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 36))
                .foregroundStyle(Color("SecondaryText"))

            Text(title)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
    }

    private var iconName: String {
        switch filter {
        case .practice: return "music.note"
        case .concert: return "music.mic"
        case .all: return "tray"
        }
    }

    private var title: String {
        switch filter {
        case .practice: return "No practice sessions yet"
        case .concert: return "No concerts logged yet"
        case .all: return "Nothing here yet"
        }
    }

    private var description: String {
        switch filter {
        case .practice:
            return "Your practice sessions will appear here once you start riyaaz."
        case .concert:
            return "Log your performances to build your concert history."
        case .all:
            return ""
        }
    }
}
