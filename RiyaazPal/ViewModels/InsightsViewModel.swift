//
//  InsightsViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-14.
//

import Foundation
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {
    
    @Published var currentWindow: DateRange = InsightWindowHelper.dateRange()
    @Published private(set) var practiceAreaMetrics: [PracticeAreaMetric] = []
    @Published private(set) var practiceRhythmMetric = PracticeRhythmCalculator.compute(sessions: [])
    @Published private(set) var activePracticeAreaCount = 0
    @Published private(set) var concertCount = 0
    @Published private(set) var isLoadingMetrics = false
    @Published private(set) var hasLoadedMetrics = false
    @Published private(set) var summaryText: String?

    private var loadedMetricsRequestID: String?
    private var metricsTask: Task<Void, Never>?
    private var loadedSummaryRequestID: String?
    private var loadingSummaryRequestID: String?

    deinit {
        metricsTask?.cancel()
    }

    func loadMetrics(
        practiceAreas: [PracticeAreaEntity],
        ratings: [PracticeAreaRatingEntity],
        sessions: [PracticeSession],
        window: DateRange,
        requestID: String
    ) {
        guard loadedMetricsRequestID != requestID else { return }

        metricsTask?.cancel()
        isLoadingMetrics = true

        let practiceAreaInputs = practiceAreas.map {
            PracticeAreaMetricAreaInput(
                id: $0.id,
                name: $0.name,
                isActive: $0.isActive,
                order: $0.order
            )
        }
        let ratingInputs = ratings.map {
            PracticeAreaMetricRatingInput(
                sessionID: $0.sessionID,
                practiceAreaID: $0.practiceAreaID,
                areaName: $0.areaName,
                didPractice: $0.didPractice,
                score: $0.score,
                createdAt: $0.createdAt,
                lastModified: $0.lastModified
            )
        }
        let sessionInputs = sessions.map {
            PracticeAreaMetricSessionInput(
                id: $0.id,
                startTime: $0.startTime,
                duration: $0.duration,
                sessionType: $0.resolvedSessionType,
                lastModified: $0.lastModified
            )
        }
        let activeAreaCount = practiceAreaInputs.filter(\.isActive).count
        let concertSessionCount = sessionInputs.filter { $0.sessionType == .concert }.count

        metricsTask = Task.detached(priority: .userInitiated) {
            let metrics = PracticeAreaMetricsCalculator.compute(
                practiceAreas: practiceAreaInputs,
                ratings: ratingInputs,
                sessions: sessionInputs,
                now: window.end
            )
            let rhythmMetric = PracticeRhythmCalculator.compute(
                sessions: sessionInputs,
                now: window.end
            )

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.practiceAreaMetrics = metrics
                self.practiceRhythmMetric = rhythmMetric
                self.activePracticeAreaCount = activeAreaCount
                self.concertCount = concertSessionCount
                self.loadedMetricsRequestID = requestID
                self.isLoadingMetrics = false
                self.hasLoadedMetrics = true
            }
        }
    }

    func loadMetricSummary(
        metrics: [PracticeAreaMetric],
        activePracticeAreaCount: Int,
        concertCount: Int,
        window: DateRange,
        requestID: String
    ) async {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            summaryText = nil
            return
        }

        guard loadedSummaryRequestID != requestID,
              loadingSummaryRequestID != requestID
        else { return }

        loadingSummaryRequestID = requestID
        summaryText = nil
        defer { loadingSummaryRequestID = nil }

        guard metrics.contains(where: { $0.ratedSessionCount > 0 || $0.concert.ratedSessionCount > 0 }) else {
            loadedSummaryRequestID = requestID
            return
        }

        do {
            let request = PracticeAreaInsightSummaryRequest(
                metrics: metrics,
                activePracticeAreaCount: activePracticeAreaCount,
                concertCount: concertCount,
                window: window
            )
            summaryText = try await PracticeAreaInsightSummaryService.generateSummary(
                request: request
            )
            loadedSummaryRequestID = requestID
        } catch {
            summaryText = nil
        }
    }
}

private enum PracticeAreaInsightSummaryService {
    static func generateSummary(
        request summaryRequest: PracticeAreaInsightSummaryRequest
    ) async throws -> String {
        guard let url = URL(string: "\(Secrets.supabaseURL)/functions/v1/reflection-signals") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Secrets.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(Secrets.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(summaryRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode
        else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(PracticeAreaInsightSummaryResponse.self, from: data).summary
    }
}

private struct PracticeAreaInsightSummaryRequest: Encodable {
    let window_start: String
    let window_end: String
    let practice: PracticeInsightPayload
    let concert: ConcertInsightPayload

    init(
        metrics: [PracticeAreaMetric],
        activePracticeAreaCount: Int,
        concertCount: Int,
        window: DateRange
    ) {
        let activeMetrics = metrics.filter(\.isActive)

        window_start = Self.dateFormatter.string(from: window.start)
        window_end = Self.dateFormatter.string(from: window.end)
        practice = PracticeInsightPayload(metrics: activeMetrics, activePracticeAreaCount: activePracticeAreaCount)
        concert = ConcertInsightPayload(metrics: activeMetrics, concertCount: concertCount)
    }

    private static let dateFormatter = ISO8601DateFormatter()
}

private struct PracticeInsightPayload: Encodable {
    let active_area_count: Int
    let rated_area_count: Int
    let latest_average: Double?
    let improving_count: Int
    let needs_attention_count: Int
    let areas: [PracticeAreaPayload]

    init(metrics: [PracticeAreaMetric], activePracticeAreaCount: Int) {
        active_area_count = activePracticeAreaCount
        rated_area_count = metrics.filter { $0.ratedSessionCount > 0 }.count
        latest_average = Self.average(metrics.compactMap(\.latestScore).map(Double.init))
        improving_count = metrics.filter { $0.trendDirection == .improving }.count
        needs_attention_count = metrics.filter {
            $0.isNeglected
            || $0.trendDirection == .declining
            || $0.performanceTransfer.status == .significantDrop
        }.count
        areas = metrics.map { PracticeAreaPayload(metric: $0) }
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

private struct ConcertInsightPayload: Encodable {
    let concert_count: Int
    let rated_area_count: Int
    let latest_average: Double?
    let significant_drop_count: Int
    let concert_lift_count: Int
    let maintained_count: Int
    let areas: [PracticeAreaPayload]

    init(metrics: [PracticeAreaMetric], concertCount: Int) {
        concert_count = concertCount
        rated_area_count = metrics.filter { $0.concert.ratedSessionCount > 0 }.count
        latest_average = Self.average(metrics.compactMap(\.concert.latestScore).map(Double.init))
        significant_drop_count = metrics.filter {
            $0.performanceTransfer.status == .significantDrop
        }.count
        concert_lift_count = metrics.filter {
            $0.performanceTransfer.status == .concertLift
        }.count
        maintained_count = metrics.filter {
            $0.performanceTransfer.status == .maintained
        }.count
        areas = metrics.map { PracticeAreaPayload(metric: $0) }
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

private struct PracticeAreaPayload: Encodable {
    let name: String
    let is_active: Bool
    let latest_score: Int?
    let seven_day_average: Double?
    let previous_seven_day_average: Double?
    let thirty_day_average: Double?
    let trend: String
    let rated_session_count: Int
    let days_since_practiced: Int?
    let is_neglected: Bool
    let volatility: Double?
    let practice: PracticeAreaContextPayload
    let concert: PracticeAreaContextPayload
    let transfer: PracticeAreaTransferPayload

    init(metric: PracticeAreaMetric) {
        name = metric.areaName
        is_active = metric.isActive
        latest_score = metric.latestScore
        seven_day_average = metric.sevenDayAverage
        previous_seven_day_average = metric.previousSevenDayAverage
        thirty_day_average = metric.thirtyDayAverage
        trend = metric.trendDirection.summaryPayloadValue
        rated_session_count = metric.ratedSessionCount
        days_since_practiced = metric.daysSincePracticed
        is_neglected = metric.isNeglected
        volatility = metric.volatility
        practice = PracticeAreaContextPayload(metric: metric.practice)
        concert = PracticeAreaContextPayload(metric: metric.concert)
        transfer = PracticeAreaTransferPayload(transfer: metric.performanceTransfer)
    }
}

private struct PracticeAreaContextPayload: Encodable {
    let latest_score: Int?
    let average_score: Double?
    let rated_session_count: Int
    let volatility: Double?

    init(metric: PracticeAreaContextMetric) {
        latest_score = metric.latestScore
        average_score = metric.averageScore
        rated_session_count = metric.ratedSessionCount
        volatility = metric.volatility
    }
}

private struct PracticeAreaTransferPayload: Encodable {
    let practice_average: Double?
    let concert_average: Double?
    let delta: Double?
    let status: String

    init(transfer: PracticeAreaPerformanceTransfer) {
        practice_average = transfer.practiceAverage
        concert_average = transfer.concertAverage
        delta = transfer.delta
        status = transfer.status.summaryPayloadValue
    }
}

private struct PracticeAreaInsightSummaryResponse: Decodable {
    let summary: String
}

private extension PracticeAreaTrendDirection {
    var summaryPayloadValue: String {
        switch self {
        case .improving:
            return "improving"
        case .declining:
            return "declining"
        case .stable:
            return "stable"
        case .insufficientData:
            return "insufficientData"
        }
    }
}

private extension PracticeAreaPerformanceTransferStatus {
    var summaryPayloadValue: String {
        switch self {
        case .significantDrop:
            return "significantDrop"
        case .concertLift:
            return "concertLift"
        case .maintained:
            return "maintained"
        case .inconclusive:
            return "inconclusive"
        case .insufficientData:
            return "insufficientData"
        }
    }
}
