//
//  PracticeRecommendationService.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-05.
//

import Foundation

struct PracticeRecommendation: Equatable {
    let title: String
    let body: String
}

enum PracticeRecommendationService {

    static func generateCopy(
        for recommendation: PracticeSuggestionRecommendation
    ) async throws -> PracticeRecommendation {
        guard let url = URL(string: "\(Secrets.supabaseURL)/functions/v1/practice-recommendation") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Secrets.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(Secrets.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            PracticeRecommendationRequest(recommendation: recommendation)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode
        else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(PracticeRecommendationResponse.self, from: data).copy
    }

    static func fallbackCopy(
        for recommendation: PracticeSuggestionRecommendation
    ) -> PracticeRecommendation {
        switch recommendation.primaryReason {
        case .noRatingsYet:
            return PracticeRecommendation(
                title: "Try \(recommendation.areaName)",
                body: "A little \(recommendation.areaName) today will help start the pattern."
            )
        case .neglected, .dueForPractice:
            return PracticeRecommendation(
                title: "\(recommendation.areaName) today",
                body: "A short round of \(recommendation.areaName) would be a good place to begin."
            )
        case .concertDrop:
            return PracticeRecommendation(
                title: "Practice \(recommendation.areaName)",
                body: "Give \(recommendation.areaName) some calm attention before it goes on stage again."
            )
        case .decliningTrend, .lowerRecentScore, .highVolatility:
            return PracticeRecommendation(
                title: "Focus on \(recommendation.areaName)",
                body: "Spend a few steady minutes with \(recommendation.areaName) today."
            )
        case .steadyMaintenance:
            return PracticeRecommendation(
                title: "Keep \(recommendation.areaName) moving",
                body: "A light touch of \(recommendation.areaName) will keep it present."
            )
        }
    }
}

private struct PracticeRecommendationRequest: Encodable {
    let area_name: String
    let primary_reason: String
    let supporting_reasons: [String]

    init(recommendation: PracticeSuggestionRecommendation) {
        area_name = recommendation.areaName
        primary_reason = recommendation.primaryReason.copyPayloadValue
        supporting_reasons = recommendation.supportingReasons.map(\.copyPayloadValue)
    }
}

private struct PracticeRecommendationResponse: Decodable {
    let title: String
    let body: String

    var copy: PracticeRecommendation {
        PracticeRecommendation(title: title, body: body)
    }
}

private extension PracticeSuggestionReason {
    var copyPayloadValue: String {
        switch self {
        case .noRatingsYet:
            return "noRatingsYet"
        case .neglected:
            return "neglected"
        case .dueForPractice:
            return "dueForPractice"
        case .concertDrop:
            return "concertDrop"
        case .decliningTrend:
            return "decliningTrend"
        case .lowerRecentScore:
            return "lowerRecentScore"
        case .highVolatility:
            return "highVolatility"
        case .steadyMaintenance:
            return "steadyMaintenance"
        }
    }
}
