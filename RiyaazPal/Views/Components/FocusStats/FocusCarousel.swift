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

    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(spacing: 4) {

            TabView(selection: $selectedIndex) {
                FocusBreakdownCard(
                    focusStats: focusStats,
                    category: TagCategory.section
                )
                .frame(width: 320)
                .tag(0)

                FocusBreakdownCard(
                    focusStats: focusStats,
                    category: TagCategory.technique
                )
                .frame(width: 320)
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 180)

            dotsIndicator
        }
    }
}

private extension FocusCarousel {

    var dotsIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(
                        index == selectedIndex
                        ? Color("PrimaryText")
                        : Color("SecondaryText").opacity(0.4)
                    )
                    .frame(width: 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
    }
}


#Preview("Focus Carousel – Light") {
    let focusStats = FocusStats(
        histogramsByCategory: [
            TagCategory.section: [
                "alap": 4,
                "taan": 2,
                "jor": 1,
            ],
            TagCategory.technique: [
                "meend": 3,
                "kan": 2,
                "gamak": 1
            ]
        ]
    )

    return FocusCarousel(focusStats: focusStats)
        .background(Color("AppBackground"))
        .preferredColorScheme(.light)
}

#Preview("Focus Carousel – Dark") {
    let focusStats = FocusStats(
        histogramsByCategory: [
            TagCategory.section: [
                "alap": 5,
                "taan": 3
            ],
            TagCategory.technique: [
                "meend": 4,
                "kan": 1
            ]
        ]
    )

    return FocusCarousel(focusStats: focusStats)
        .padding()
        .background(Color("AppBackground"))
        .preferredColorScheme(.dark)
}
