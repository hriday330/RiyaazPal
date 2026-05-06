//
//  PracticeRecommendationService.swift
//  RiyaazPal
//
//  Created by Codex on 2026-05-05.
//

import Foundation

struct PracticeRecommendation: Equatable {
    let recommendation: PracticeSuggestionRecommendation
    let title: String
    let body: String
}

enum PracticeRecommendationService {

    static let defaultShortlistLimit = 5

    static func generateRecommendation(
        from recommendations: [PracticeSuggestionRecommendation],
        shortlistLimit: Int = defaultShortlistLimit
    ) async throws -> PracticeRecommendation {
        let shortlist = Array(recommendations.prefix(shortlistLimit))

        guard let fallbackRecommendation = shortlist.first else {
            throw URLError(.badURL)
        }

        guard let url = URL(string: "\(Secrets.supabaseURL)/functions/v1/practice-recommendation") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Secrets.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(Secrets.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            PracticeRecommendationRequest(recommendations: shortlist)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode
        else {
            throw URLError(.badServerResponse)
        }

        let recommendationResponse = try JSONDecoder().decode(PracticeRecommendationResponse.self, from: data)
        return recommendationResponse.recommendation(
            from: shortlist,
            fallback: fallbackRecommendation
        )
    }

    static func generateRecommendation(
        for recommendation: PracticeSuggestionRecommendation
    ) async throws -> PracticeRecommendation {
        try await generateRecommendation(from: [recommendation], shortlistLimit: 1)
    }

    static func fallbackCopy(
        for recommendation: PracticeSuggestionRecommendation
    ) -> PracticeRecommendation {
        switch recommendation.primaryReason {
        case .noRatingsYet:
            return PracticeRecommendation(
                recommendation: recommendation,
                title: "Try \(recommendation.areaName)",
                body: "A little \(recommendation.areaName) today will help start the pattern."
            )
        case .neglected, .dueForPractice:
            return PracticeRecommendation(
                recommendation: recommendation,
                title: "\(recommendation.areaName) today",
                body: "A short round of \(recommendation.areaName) would be a good place to begin."
            )
        case .concertDrop:
            return PracticeRecommendation(
                recommendation: recommendation,
                title: "Practice \(recommendation.areaName)",
                body: "Give \(recommendation.areaName) some calm attention before it goes on stage again."
            )
        case .decliningTrend, .lowerRecentScore, .highVolatility:
            return PracticeRecommendation(
                recommendation: recommendation,
                title: "Focus on \(recommendation.areaName)",
                body: "Spend a few steady minutes with \(recommendation.areaName) today."
            )
        case .steadyMaintenance:
            return PracticeRecommendation(
                recommendation: recommendation,
                title: "Keep \(recommendation.areaName) moving",
                body: "A light touch of \(recommendation.areaName) will keep it present."
            )
        }
    }
}

private struct PracticeRecommendationRequest: Encodable {
    let candidates: [PracticeRecommendationCandidatePayload]

    init(recommendations: [PracticeSuggestionRecommendation]) {
        candidates = recommendations.enumerated().map { index, recommendation in
            PracticeRecommendationCandidatePayload(
                recommendation: recommendation,
                rank: index + 1
            )
        }
    }
}

private struct PracticeRecommendationCandidatePayload: Encodable {
    let id: String
    let area_name: String
    let rank: Int
    let priority_score: Double
    let primary_reason: String
    let supporting_reasons: [String]

    init(
        recommendation: PracticeSuggestionRecommendation,
        rank: Int
    ) {
        id = recommendation.stableSelectionID
        area_name = recommendation.areaName
        self.rank = rank
        priority_score = recommendation.priorityScore
        primary_reason = recommendation.primaryReason.copyPayloadValue
        supporting_reasons = recommendation.supportingReasons.map(\.copyPayloadValue)
    }
}

private struct PracticeRecommendationResponse: Decodable {
    let selected_id: String
    let title: String
    let body: String

    func recommendation(
        from recommendations: [PracticeSuggestionRecommendation],
        fallback: PracticeSuggestionRecommendation
    ) -> PracticeRecommendation {
        let selectedRecommendation = recommendations.first {
            $0.stableSelectionID == selected_id
        } ?? fallback

        return PracticeRecommendation(
            recommendation: selectedRecommendation,
            title: title,
            body: body
        )
    }
}

private extension PracticeSuggestionRecommendation {
    var stableSelectionID: String {
        areaID?.uuidString ?? areaName
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
