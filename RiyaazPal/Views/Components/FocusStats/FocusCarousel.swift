//
//  FocusCarousel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-08.
//

import Foundation
import SwiftUI

let section = TagCategory(
    id: UUID(),
    name: "Section",
    isFocusRelevant: true
)

let technique = TagCategory(
    id: UUID(),
    name: "Technique",
    isFocusRelevant: true
)

struct FocusCarousel: View {

    let focusStats: FocusStats
    let categories: [TagCategory]
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(spacing: 4) {

            TabView(selection: $selectedIndex) {
                ForEach(Array(categories.enumerated()), id: \.element.id) 
                    { index, category in
                        FocusBreakdownCard(
                            focusStats: focusStats,
                            category: category
                        )
                        .frame(width: 320)
                        .tag(index)
                    }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 300)

            dotsIndicator
        }.padding(10)
    }
}

private extension FocusCarousel {
    var dotsIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<categories.count, id: \.self) { index in
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
            section: [
                "alap": 4,
                "taan": 2,
                "jor": 1,
            ],
            technique: [
                "meend": 3,
                "kan": 2,
                "gamak": 1
            ]
        ]
    )

    return FocusCarousel(focusStats: focusStats, categories: [section, technique])
        .background(Color("AppBackground"))
        .preferredColorScheme(.light)
}

#Preview("Focus Carousel – Dark") {
    let focusStats = FocusStats(
        histogramsByCategory: [
            section: [
                "alap": 5,
                "taan": 3
            ],
            technique: [
                "meend": 4,
                "kan": 1
            ]
        ]
    )

    return FocusCarousel(focusStats: focusStats, categories: [section, technique])
        .padding()
        .background(Color("AppBackground"))
        .preferredColorScheme(.dark)
}
