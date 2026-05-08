//
//  PracticeRecommendationCard.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-05.
//

import SwiftUI

struct PracticeRecommendationCard: View {
    let recommendation: PracticeRecommendation?
    let isLoading: Bool
    let isSessionActive: Bool
    let onUseFocus: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's focus")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("SecondaryText"))
                        .textCase(.uppercase)

                    if isLoading {
                        loadingContent
                    } else if let recommendation {
                        recommendationContent(recommendation)
                    }
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("SecondaryText"))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss today's focus")
            }

            Button(action: onUseFocus) {
                Label(
                    buttonTitle,
                    systemImage: buttonIcon
                )
                .font(.caption)
                .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .tint(Color("AccentColor"))
            .disabled(isLoading || isSessionActive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private var loadingContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("SecondaryText").opacity(0.18))
                .frame(width: 150, height: 12)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color("SecondaryText").opacity(0.12))
                .frame(maxWidth: 260)
                .frame(height: 10)
        }
    }

    private func recommendationContent(
        _ recommendation: PracticeRecommendation
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recommendation.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryText"))

            Text(recommendation.body)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var buttonTitle: String {
        if isLoading {
            return "Loading"
        }

        return isSessionActive ? "Session running" : "Use this focus"
    }

    private var buttonIcon: String {
        if isLoading {
            return "hourglass"
        }

        return isSessionActive ? "timer" : "play.fill"
    }
}
