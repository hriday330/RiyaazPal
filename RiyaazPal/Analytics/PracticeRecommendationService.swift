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
                title: "Work on \(recommendation.areaName)",
                body: "Use today's session to get a first rating for \(recommendation.areaName)."
            )
        case .neglected, .dueForPractice:
            return PracticeRecommendation(
                recommendation: recommendation,
                title: "\(recommendation.areaName) today",
                body: "Spend part of this session on \(recommendation.areaName)."
            )
        case .concertDrop:
            return PracticeRecommendation(
                recommendation: recommendation,
                title: "Practice \(recommendation.areaName)",
                body: "Work on making \(recommendation.areaName) hold up in performance."
            )
        case .decliningTrend, .lowerRecentScore, .highVolatility:
            return PracticeRecommendation(
                recommendation: recommendation,
                title: "Focus on \(recommendation.areaName)",
                body: "Use part of today's practice for \(recommendation.areaName)."
            )
        case .steadyMaintenance:
            return PracticeRecommendation(
                recommendation: recommendation,
                title: "Keep \(recommendation.areaName) moving",
                body: "Include \(recommendation.areaName) in today's session."
            )
        }
    }
}

@MainActor
enum PracticeRecommendationSessionCache {
    private static var cachedRecommendation: PracticeRecommendation?
    private static var inFlightRecommendationTask: Task<PracticeRecommendation, Error>?

    static var recommendation: PracticeRecommendation? {
        cachedRecommendation
    }

    static func store(
        _ recommendation: PracticeRecommendation
    ) {
        cachedRecommendation = recommendation
    }

    static func generateRecommendation(
        from recommendations: [PracticeSuggestionRecommendation]
    ) async throws -> PracticeRecommendation {
        if let cachedRecommendation {
            return cachedRecommendation
        }

        if let inFlightRecommendationTask {
            let recommendation = try await inFlightRecommendationTask.value
            cachedRecommendation = recommendation
            return recommendation
        }

        let task = Task {
            try await PracticeRecommendationService.generateRecommendation(
                from: recommendations
            )
        }

        inFlightRecommendationTask = task

        do {
            let recommendation = try await task.value
            cachedRecommendation = recommendation
            inFlightRecommendationTask = nil
            return recommendation
        } catch {
            inFlightRecommendationTask = nil
            throw error
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
