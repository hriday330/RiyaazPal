//
//  SessionTypeChip.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-06.
//

import Foundation
import SwiftUI

struct SessionTypeChip: View {
    let type: SessionType

    var body: some View {
        if type == .concert {
            HStack(spacing: 4) {
                Image(systemName: "music.mic")
                    .font(.system(size: 10, weight: .semibold))

                Text("Concert")
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color("ConcertChipBackground"))
            )
            .foregroundStyle(Color("ConcertChipText"))
        }
    }
}
