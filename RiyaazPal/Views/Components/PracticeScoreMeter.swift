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

    @State private var animatedScore: Double = 0

    private var clampedScore: Int {
        min(max(score, 0), 100)
    }

    private var normalizedScore: Double {
        Double(clampedScore) / 100.0
    }

    private var scoreBand: ScoreBand {
        ScoreBand(score: clampedScore)
    }

    private var subtitle: String {
        scoreBand.subtitle
    }

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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

                    Text("\(clampedScore)")
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

    private var scoreLabel: String {
        scoreBand.label
    }
}

private enum ScoreBand {
    case excellent
    case strong
    case steady
    case needsAttention

    init(score: Int) {
        switch score {
        case 85...100:
            self = .excellent
        case 70..<85:
            self = .strong
        case 50..<70:
            self = .steady
        default:
            self = .needsAttention
        }
    }

    var label: String {
        switch self {
        case .excellent:      return "Excellent"
        case .strong:         return "Strong"
        case .steady:         return "Steady"
        case .needsAttention: return "Needs Attention"
        }
    }

    var subtitle: String {
        switch self {
        case .excellent:
            return "Highly consistent, well-balanced practice"
        case .strong:
            return "Consistent practice with good structural balance"
        case .steady:
            return "Regular practice, with room for refinement"
        case .needsAttention:
            return "Inconsistent practice pattern this period"
        }
    }
}

#Preview("Practice Score Meter – Light") {
    VStack {
        PracticeScoreMeter(score: 78)
        PracticeScoreMeter(score: 50)
    }
    .padding()
    .background(Color("AppBackground"))
    .preferredColorScheme(.light)
}

#Preview("Practice Score Meter – Dark") {
    PracticeScoreMeter(score: 90)
        .padding()
        .background(Color("AppBackground"))
        .preferredColorScheme(.dark)
}
