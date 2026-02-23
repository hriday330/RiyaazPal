//
//  ReflectionInsightService.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-12.
//

import Foundation

enum ReflectionInsightService {

    static func generateInsight(
        sessions: [PracticeSession],
        goals: [GoalEntity],
        categories: [TagCategoryModel],
        window: DateRange
    ) async throws -> ReflectionInsight {

        let requestBody = try buildRequest(
            sessions: sessions,
            goals: goals,
            categories: categories,
            window: window
        )

        return try await callEdgeFunction(body: requestBody)
    }

}

struct ReflectionInsight: Decodable {
    let items: [InsightItem]
}

struct InsightItem: Decodable {
    let item: String
    let confidence_delta: Int
    let evidence: String
}

private struct ReflectionRequestBody: Encodable {
    let week_start: String
    let reflections: [ReflectionEntry]
    let goals: [GoalEntry]
    let categories: [CategoryEntry]

    struct ReflectionEntry: Encodable {
        let date: String
        let notes: String
        let metrics: [String: Double]
    }

    struct GoalEntry: Encodable {
        let type: String
        let tag: String
        let intent: String?
    }
    
    struct CategoryEntry: Encodable {
        let name: String
        let tags: [String]
    }
}


private extension ReflectionInsightService {

    static func buildRequest(
        sessions: [PracticeSession],
        goals: [GoalEntity],
        categories: [TagCategoryModel],
        window: DateRange
    ) throws -> ReflectionRequestBody {

        let fullDateFormatter = ISO8601DateFormatter()
        fullDateFormatter.formatOptions = [.withFullDate]

        let dateTimeFormatter = ISO8601DateFormatter()
        dateTimeFormatter.formatOptions = [.withInternetDateTime]

        let reflections = sessions
            .filter { window.contains($0.startTime) }
            .compactMap { session -> ReflectionRequestBody.ReflectionEntry? in
                let notes = session.detailedNotes
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !notes.isEmpty else { return nil }

                return .init(
                    date: dateTimeFormatter.string(from: session.startTime),
                    notes: notes,
                    metrics: [:]
                )
            }

        guard !reflections.isEmpty else {
            throw InsightError.noValidReflections
        }

        let goalEntries = goals
            .filter { $0.isActive }
            .map {
                ReflectionRequestBody.GoalEntry(
                    type: $0.type.rawValue,
                    tag: $0.tagName,
                    intent: $0.intent?.rawValue
                )
            }

        let categoryEntries = categories.map {
            ReflectionRequestBody.CategoryEntry(
                name: $0.name,
                tags: $0.tags
            )
        }
        return ReflectionRequestBody(
            week_start: fullDateFormatter.string(from: window.start),
            reflections: reflections,
            goals: goalEntries,
            categories: categoryEntries
        )
    }

}

enum InsightError: LocalizedError {
    case noValidReflections

    var errorDescription: String? {
        "Not enough reflection data to generate insights."
    }
}

private extension ReflectionInsightService {

    static func callEdgeFunction(
        body: ReflectionRequestBody
    ) async throws -> ReflectionInsight {

        let url = URL(string:
            Secrets.supabaseURL + "/functions/v1/reflection-signals"
        )!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "Bearer \(Secrets.supabaseAnonKey)",
            forHTTPHeaderField: "Authorization"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        
        guard status == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(ReflectionInsight.self, from: data)
    }

}
