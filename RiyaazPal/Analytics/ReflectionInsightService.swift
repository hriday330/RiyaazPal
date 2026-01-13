//
//  ReflectionInsightService.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-12.
//

import Foundation

enum ReflectionInsightService {

    /// Main entry point used by InsightsView / ViewModel
    static func generateInsight(
        sessions: [PracticeSession],
        window: DateRange
    ) async throws -> ReflectionInsight {

        let requestBody = try buildRequest(
            sessions: sessions,
            window: window
        )

        return try await callEdgeFunction(body: requestBody)
    }

}

// MARK: - Response Models (must match Edge Function)

struct ReflectionInsight: Decodable {
    let items: [InsightItem]
}

struct InsightItem: Decodable {
    let item: String
    let confidence_delta: Int
    let evidence: String
}

// MARK: - Request Payload

private struct ReflectionRequestBody: Encodable {
    let week_start: String
    let reflections: [ReflectionEntry]

    struct ReflectionEntry: Encodable {
        let date: String
        let notes: String
        let metrics: [String: Double]
    }
}

// MARK: - Request Builder

private extension ReflectionInsightService {

    static func buildRequest(
        sessions: [PracticeSession],
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
                    metrics: [:] // reserved for future deterministic signals
                )
            }

        guard !reflections.isEmpty else {
            throw InsightError.noValidReflections
        }

        return ReflectionRequestBody(
            week_start: fullDateFormatter.string(from: window.start),
            reflections: reflections
        )
    }
}

enum InsightError: LocalizedError {
    case noValidReflections

    var errorDescription: String? {
        "Not enough reflection data to generate insights."
    }
}


// MARK: - Edge Function Call

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
        print("Edge status:", status)

        let text = String(decoding: data, as: UTF8.self)
        print("Edge raw response:", text)

        guard status == 200 else {
            throw URLError(.badServerResponse)
        }

        // 6. Decode
        return try JSONDecoder().decode(ReflectionInsight.self, from: data)
    }

}
