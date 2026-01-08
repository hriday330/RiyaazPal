//
//  FocusCarousel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-08.
//

import Foundation
import SwiftUI

struct FocusCarousel: View {

    let focusStats: FocusStats

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                FocusBreakdownCard(
                    focusStats: focusStats,
                    category: .section
                )
                .frame(width: 320)

                FocusBreakdownCard(
                    focusStats: focusStats,
                    category: .technique
                )
                .frame(width: 320)
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
    }
}


