//
//  PracticeScoreMeter.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-07.
//

import Foundation
import SwiftUI

struct PracticeScoreMeter: View {

    let score: Int
    let subtitle: String

    @State private var animatedScore: Double = 0
    
    private var normalizedScore: Double {
        Double(min(max(score, 0), 100)) / 100.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Practice Health")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            HStack(alignment: .center, spacing: 20) {

                ZStack {
                    Circle()
                        .stroke(
                            Color("CardBorder").opacity(0.25),
                            lineWidth: 10
                        )

                    Circle()
                        .trim(from: 0, to: animatedScore)
                        .stroke(
                            Color("AccentColor"),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round
                            )
                        )
                    
                        .rotationEffect(.degrees(-90))
                        

                    Text("\(score)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color("PrimaryText"))
                }
                .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 6) {
                    Text(scoreLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("PrimaryText"))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                    animatedScore = normalizedScore
                }
                }
    }

    // TODO: Improve labels for this 
    private var scoreLabel: String {
        switch score {
        case 85...100: return "Excellent"
        case 70..<85:  return "Strong"
        case 50..<70:  return "Steady"
        default:       return "Needs Attention"
        }
    }
}


#Preview("Practice Score Meter – Light") {
    VStack {
        PracticeScoreMeter(
            score: 78,
            subtitle: "Consistent practice with strong technical focus"
        )
        PracticeScoreMeter(
            score: 62,
            subtitle: "Regular practice, but focus is uneven"
        )
    }
    .padding()
    .background(Color("AppBackground"))
    .preferredColorScheme(.light)
}

#Preview("Practice Score Meter – Dark") {
    PracticeScoreMeter(
        score: 90,
        subtitle: "Excellent consistency and balanced focus"
    )
    .padding()
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}
