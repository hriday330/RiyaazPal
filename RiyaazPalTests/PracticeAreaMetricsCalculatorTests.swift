//
//  PracticeAreaMetricsCalculatorTests.swift
//  RiyaazPalTests
//
//  Created by Hriday Buddhdev on 2026-06-02.
//

import XCTest
@testable import RiyaazPal

final class PracticeAreaMetricsCalculatorTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testImprovingTrendComparesSevenDayWindows() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(5, daysAgo: 10, areaID: areaID),
                score(7, daysAgo: 2, areaID: areaID)
            ]
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.trendDirection, .improving)
        XCTAssertEqual(metric.sevenDayAverage, 7)
        XCTAssertEqual(metric.previousSevenDayAverage, 5)
    }

    func testMissedPracticeIsNeglectedWithoutDecliningTrend() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(8, daysAgo: 8, areaID: areaID)
            ]
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertNil(metric.sevenDayAverage)
        XCTAssertEqual(metric.previousSevenDayAverage, 8)
        XCTAssertEqual(metric.trendDirection, .insufficientData)
        XCTAssertEqual(metric.daysSincePracticed, 8)
        XCTAssertTrue(metric.isNeglected)
    }

    func testPerformanceTransferDetectsConcertDrop() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(8, daysAgo: 7, areaID: areaID),
                score(8, daysAgo: 6, areaID: areaID),
                score(9, daysAgo: 5, areaID: areaID),
                score(9, daysAgo: 4, areaID: areaID),
                score(6, daysAgo: 3, areaID: areaID, sessionType: .concert),
                score(6, daysAgo: 2, areaID: areaID, sessionType: .concert),
                score(6, daysAgo: 1, areaID: areaID, sessionType: .concert)
            ]
        )

        let transfer = try XCTUnwrap(metrics.first?.performanceTransfer)
        XCTAssertEqual(try XCTUnwrap(transfer.practiceAverage), 8.5)
        XCTAssertEqual(try XCTUnwrap(transfer.concertAverage), 6)
        XCTAssertEqual(try XCTUnwrap(transfer.delta), -2.5)
        XCTAssertEqual(transfer.status, .significantDrop)
    }

    func testPerformanceTransferDetectsMaintainedConcertExecution() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(7, daysAgo: 7, areaID: areaID),
                score(8, daysAgo: 6, areaID: areaID),
                score(8, daysAgo: 5, areaID: areaID),
                score(9, daysAgo: 4, areaID: areaID),
                score(7, daysAgo: 3, areaID: areaID, sessionType: .concert),
                score(8, daysAgo: 2, areaID: areaID, sessionType: .concert),
                score(8, daysAgo: 1, areaID: areaID, sessionType: .concert)
            ]
        )

        let transfer = try XCTUnwrap(metrics.first?.performanceTransfer)
        XCTAssertEqual(try XCTUnwrap(transfer.practiceAverage), 8)
        XCTAssertEqual(
            try XCTUnwrap(transfer.concertAverage),
            7.666666666666667,
            accuracy: 0.0001
        )
        XCTAssertEqual(transfer.status, .maintained)
    }

    func testUsesNewestRatingWhenSessionHasDuplicateAreaRatings() throws {
        let areaID = UUID()
        let sessionID = UUID()
        let now = try date("2026-06-02T12:00:00Z")
        let sessionDate = try date("2026-06-01T12:00:00Z")

        let sessions = [
            session(id: sessionID, startTime: sessionDate, sessionType: .practice)
        ]
        let ratings = [
            rating(
                sessionID: sessionID,
                areaID: areaID,
                areaName: "Alap",
                score: 4,
                createdAt: sessionDate,
                lastModified: try date("2026-06-01T12:05:00Z")
            ),
            rating(
                sessionID: sessionID,
                areaID: areaID,
                areaName: "Alap",
                score: 9,
                createdAt: sessionDate,
                lastModified: try date("2026-06-01T12:10:00Z")
            )
        ]

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Alap")],
            ratings: ratings,
            sessions: sessions,
            now: now,
            calendar: calendar
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.latestScore, 9)
        XCTAssertEqual(metric.ratedSessionCount, 1)
        XCTAssertEqual(metric.practice.averageScore, 9)
    }
}

private extension PracticeAreaMetricsCalculatorTests {
    struct ScoreFixture {
        let score: Int
        let daysAgo: Int
        let areaID: UUID
        let sessionType: SessionType
    }

    func compute(
        areaID: UUID,
        now: Date,
        scores: [ScoreFixture]
    ) -> [PracticeAreaMetric] {
        let sessions = scores.enumerated().map { index, fixture in
            session(
                id: sessionID(index),
                startTime: calendar.date(
                    byAdding: .day,
                    value: -fixture.daysAgo,
                    to: now
                ) ?? now,
                sessionType: fixture.sessionType
            )
        }

        let ratings = zip(scores.indices, scores).map { index, fixture in
            let sessionDate = sessions[index].startTime
            return rating(
                sessionID: sessionID(index),
                areaID: fixture.areaID,
                areaName: "Alap",
                score: fixture.score,
                createdAt: sessionDate,
                lastModified: sessionDate
            )
        }

        return PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Alap")],
            ratings: ratings,
            sessions: sessions,
            now: now,
            calendar: calendar
        )
    }

    func score(
        _ value: Int,
        daysAgo: Int,
        areaID: UUID,
        sessionType: SessionType = .practice
    ) -> ScoreFixture {
        ScoreFixture(
            score: value,
            daysAgo: daysAgo,
            areaID: areaID,
            sessionType: sessionType
        )
    }

    func area(
        id: UUID,
        name: String,
        isActive: Bool = true,
        order: Int = 0
    ) -> PracticeAreaMetricAreaInput {
        PracticeAreaMetricAreaInput(
            id: id,
            name: name,
            isActive: isActive,
            order: order
        )
    }

    func session(
        id: UUID,
        startTime: Date,
        sessionType: SessionType
    ) -> PracticeAreaMetricSessionInput {
        PracticeAreaMetricSessionInput(
            id: id,
            startTime: startTime,
            duration: 45 * 60,
            sessionType: sessionType,
            lastModified: startTime
        )
    }

    func rating(
        sessionID: UUID,
        areaID: UUID,
        areaName: String,
        score: Int,
        createdAt: Date,
        lastModified: Date
    ) -> PracticeAreaMetricRatingInput {
        PracticeAreaMetricRatingInput(
            sessionID: sessionID,
            practiceAreaID: areaID,
            areaName: areaName,
            didPractice: true,
            score: score,
            createdAt: createdAt,
            lastModified: lastModified
        )
    }

    func sessionID(_ index: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", index + 1))")!
    }

    func date(_ string: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        return try XCTUnwrap(formatter.date(from: string))
    }
}
