//
//  PracticeAreaMetricsCalculatorTests.swift
//  RiyaazPalTests
//
//  Created by Hriday Buddhdev on 2026-06-02.
//

import XCTest

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

    func testDecliningTrendComparesSevenDayWindows() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(8, daysAgo: 10, areaID: areaID),
                score(6, daysAgo: 2, areaID: areaID)
            ]
        )

        XCTAssertEqual(try XCTUnwrap(metrics.first).trendDirection, .declining)
    }

    func testStableTrendWhenSevenDayDeltaIsBelowThreshold() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(7, daysAgo: 10, areaID: areaID),
                score(7, daysAgo: 2, areaID: areaID)
            ]
        )

        XCTAssertEqual(try XCTUnwrap(metrics.first).trendDirection, .stable)
    }

    func testTrendIsInsufficientWhenPreviousWindowIsEmpty() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(7, daysAgo: 2, areaID: areaID)
            ]
        )

        XCTAssertEqual(try XCTUnwrap(metrics.first).trendDirection, .insufficientData)
    }

    func testActiveAreaWithNoRatingsAppearsAndIsNeglected() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Alap")],
            ratings: [],
            sessions: [],
            now: now,
            calendar: calendar
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.areaName, "Alap")
        XCTAssertTrue(metric.isActive)
        XCTAssertTrue(metric.isNeglected)
        XCTAssertNil(metric.latestScore)
        XCTAssertEqual(metric.ratedSessionCount, 0)
    }

    func testInactiveAreaWithNoRatingsIsOmitted() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Archived Alap", isActive: false)],
            ratings: [],
            sessions: [],
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(metrics.isEmpty)
    }

    func testExactlyFiveDaysSincePracticedIsNotNeglected() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(7, daysAgo: 5, areaID: areaID)
            ]
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.daysSincePracticed, 5)
        XCTAssertFalse(metric.isNeglected)
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

    func testPerformanceTransferDetectsConcertLift() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(5, daysAgo: 7, areaID: areaID),
                score(5, daysAgo: 6, areaID: areaID),
                score(6, daysAgo: 5, areaID: areaID),
                score(6, daysAgo: 4, areaID: areaID),
                score(8, daysAgo: 3, areaID: areaID, sessionType: .concert),
                score(8, daysAgo: 2, areaID: areaID, sessionType: .concert),
                score(8, daysAgo: 1, areaID: areaID, sessionType: .concert)
            ]
        )

        let transfer = try XCTUnwrap(metrics.first?.performanceTransfer)
        XCTAssertEqual(try XCTUnwrap(transfer.delta), 2.5)
        XCTAssertEqual(transfer.status, .concertLift)
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

    func testPerformanceTransferIsInsufficientWithTooFewPracticeScores() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(8, daysAgo: 6, areaID: areaID),
                score(8, daysAgo: 5, areaID: areaID),
                score(8, daysAgo: 4, areaID: areaID),
                score(6, daysAgo: 3, areaID: areaID, sessionType: .concert),
                score(6, daysAgo: 2, areaID: areaID, sessionType: .concert),
                score(6, daysAgo: 1, areaID: areaID, sessionType: .concert)
            ]
        )

        let transfer = try XCTUnwrap(metrics.first?.performanceTransfer)
        XCTAssertEqual(transfer.status, .insufficientData)
        XCTAssertNil(transfer.delta)
    }

    func testPerformanceTransferIsInsufficientWithTooFewConcertScores() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(8, daysAgo: 6, areaID: areaID),
                score(8, daysAgo: 5, areaID: areaID),
                score(8, daysAgo: 4, areaID: areaID),
                score(8, daysAgo: 3, areaID: areaID),
                score(6, daysAgo: 2, areaID: areaID, sessionType: .concert),
                score(6, daysAgo: 1, areaID: areaID, sessionType: .concert)
            ]
        )

        let transfer = try XCTUnwrap(metrics.first?.performanceTransfer)
        XCTAssertEqual(transfer.status, .insufficientData)
        XCTAssertNil(transfer.delta)
    }

    func testPerformanceTransferIsMaintainedAtExactThresholds() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let dropBoundaryMetrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(8, daysAgo: 7, areaID: areaID),
                score(8, daysAgo: 6, areaID: areaID),
                score(9, daysAgo: 5, areaID: areaID),
                score(9, daysAgo: 4, areaID: areaID),
                score(7, daysAgo: 3, areaID: areaID, sessionType: .concert),
                score(7, daysAgo: 2, areaID: areaID, sessionType: .concert),
                score(7, daysAgo: 1, areaID: areaID, sessionType: .concert)
            ]
        )

        XCTAssertEqual(try XCTUnwrap(dropBoundaryMetrics.first?.performanceTransfer.status), .maintained)

        let liftBoundaryMetrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(6, daysAgo: 7, areaID: areaID),
                score(6, daysAgo: 6, areaID: areaID),
                score(7, daysAgo: 5, areaID: areaID),
                score(7, daysAgo: 4, areaID: areaID),
                score(8, daysAgo: 3, areaID: areaID, sessionType: .concert),
                score(8, daysAgo: 2, areaID: areaID, sessionType: .concert),
                score(8, daysAgo: 1, areaID: areaID, sessionType: .concert)
            ]
        )

        XCTAssertEqual(try XCTUnwrap(liftBoundaryMetrics.first?.performanceTransfer.status), .maintained)
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

    func testRatingsWithoutMatchingSessionAreIgnored() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Alap")],
            ratings: [
                rating(
                    sessionID: UUID(),
                    areaID: areaID,
                    areaName: "Alap",
                    score: 8,
                    createdAt: now,
                    lastModified: now
                )
            ],
            sessions: [],
            now: now,
            calendar: calendar
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertNil(metric.latestScore)
        XCTAssertEqual(metric.ratedSessionCount, 0)
    }

    func testDidNotPracticeAndNilScoreRatingsAreIgnored() throws {
        let areaID = UUID()
        let sessionID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Alap")],
            ratings: [
                rating(
                    sessionID: sessionID,
                    areaID: areaID,
                    areaName: "Alap",
                    didPractice: false,
                    score: 8,
                    createdAt: now,
                    lastModified: now
                ),
                rating(
                    sessionID: sessionID,
                    areaID: areaID,
                    areaName: "Alap",
                    score: nil,
                    createdAt: now,
                    lastModified: now
                )
            ],
            sessions: [
                session(id: sessionID, startTime: now, sessionType: .practice)
            ],
            now: now,
            calendar: calendar
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertNil(metric.latestScore)
        XCTAssertEqual(metric.ratedSessionCount, 0)
    }

    func testScoresAreClampedBeforeMetricsAreCalculated() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(20, daysAgo: 2, areaID: areaID),
                score(-4, daysAgo: 1, areaID: areaID)
            ]
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.latestScore, 1)
        XCTAssertEqual(metric.sevenDayAverage, 5.5)
    }

    func testArchivedAreaWithOldRatingsProducesArchivedMetric() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Archived Alap", isActive: false)],
            ratings: [
                rating(
                    sessionID: sessionID(0),
                    areaID: areaID,
                    areaName: "Old Alap",
                    score: 8,
                    createdAt: now,
                    lastModified: now
                )
            ],
            sessions: [
                session(id: sessionID(0), startTime: now, sessionType: .practice)
            ],
            now: now,
            calendar: calendar
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.areaName, "Archived Alap")
        XCTAssertFalse(metric.isActive)
        XCTAssertFalse(metric.isNeglected)
    }

    func testRenamedActiveAreaUsesCurrentAreaName() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Alaap")],
            ratings: [
                rating(
                    sessionID: sessionID(0),
                    areaID: areaID,
                    areaName: "Alap",
                    score: 8,
                    createdAt: now,
                    lastModified: now
                )
            ],
            sessions: [
                session(id: sessionID(0), startTime: now, sessionType: .practice)
            ],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(try XCTUnwrap(metrics.first).areaName, "Alaap")
    }

    func testUnknownAreaFallsBackToSavedRatingName() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [],
            ratings: [
                rating(
                    sessionID: sessionID(0),
                    areaID: areaID,
                    areaName: "Snapshot Name",
                    score: 8,
                    createdAt: now,
                    lastModified: now
                )
            ],
            sessions: [
                session(id: sessionID(0), startTime: now, sessionType: .practice)
            ],
            now: now,
            calendar: calendar
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.areaName, "Snapshot Name")
        XCTAssertFalse(metric.isActive)
    }

    func testMultipleSessionsOnSameDayAreAllCounted() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")
        let morning = try date("2026-06-02T09:00:00Z")
        let lateMorning = try date("2026-06-02T11:00:00Z")

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Alap")],
            ratings: [
                rating(sessionID: sessionID(0), areaID: areaID, areaName: "Alap", score: 6, createdAt: morning, lastModified: morning),
                rating(sessionID: sessionID(1), areaID: areaID, areaName: "Alap", score: 8, createdAt: lateMorning, lastModified: lateMorning)
            ],
            sessions: [
                session(id: sessionID(0), startTime: morning, sessionType: .practice),
                session(id: sessionID(1), startTime: lateMorning, sessionType: .practice)
            ],
            now: now,
            calendar: calendar
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.ratedSessionCount, 2)
        XCTAssertEqual(metric.sevenDayAverage, 7)
    }

    func testFutureDatedSessionDoesNotCreateNegativeDaysSincePracticed() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(8, daysAgo: -2, areaID: areaID)
            ]
        )

        XCTAssertEqual(try XCTUnwrap(metrics.first).daysSincePracticed, 0)
    }

    func testScoreHistoryIsSortedOldestToNewest() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(8, daysAgo: 1, areaID: areaID),
                score(6, daysAgo: 3, areaID: areaID),
                score(7, daysAgo: 2, areaID: areaID)
            ]
        )

        XCTAssertEqual(try XCTUnwrap(metrics.first).scoreHistory.map(\.score), [6, 7, 8])
    }

    func testLatestScoreUsesLatestSessionDateNotLatestModifiedRating() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")
        let olderSessionDate = try date("2026-05-30T12:00:00Z")
        let newerSessionDate = try date("2026-06-01T12:00:00Z")

        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [area(id: areaID, name: "Alap")],
            ratings: [
                rating(
                    sessionID: sessionID(0),
                    areaID: areaID,
                    areaName: "Alap",
                    score: 10,
                    createdAt: olderSessionDate,
                    lastModified: try date("2026-06-02T11:00:00Z")
                ),
                rating(
                    sessionID: sessionID(1),
                    areaID: areaID,
                    areaName: "Alap",
                    score: 6,
                    createdAt: newerSessionDate,
                    lastModified: newerSessionDate
                )
            ],
            sessions: [
                session(id: sessionID(0), startTime: olderSessionDate, sessionType: .practice),
                session(id: sessionID(1), startTime: newerSessionDate, sessionType: .practice)
            ],
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(try XCTUnwrap(metrics.first).latestScore, 6)
    }

    func testPracticeAndConcertContextLatestScoresAreSeparated() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(7, daysAgo: 4, areaID: areaID),
                score(8, daysAgo: 3, areaID: areaID, sessionType: .concert),
                score(9, daysAgo: 2, areaID: areaID),
                score(6, daysAgo: 1, areaID: areaID, sessionType: .concert)
            ]
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.practice.latestScore, 9)
        XCTAssertEqual(metric.concert.latestScore, 6)
    }

    func testVolatilityIsNilForOneScoreZeroForIdenticalScoresAndPositiveForMixedScores() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        XCTAssertNil(try XCTUnwrap(compute(areaID: areaID, now: now, scores: [
            score(7, daysAgo: 1, areaID: areaID)
        ]).first).volatility)

        XCTAssertEqual(try XCTUnwrap(try XCTUnwrap(compute(areaID: areaID, now: now, scores: [
            score(7, daysAgo: 2, areaID: areaID),
            score(7, daysAgo: 1, areaID: areaID)
        ]).first).volatility), 0)

        XCTAssertEqual(try XCTUnwrap(try XCTUnwrap(compute(areaID: areaID, now: now, scores: [
            score(6, daysAgo: 2, areaID: areaID),
            score(8, daysAgo: 1, areaID: areaID)
        ]).first).volatility), 1)
    }

    func testNoPracticeAreasAndNoRatingsReturnsNoMetrics() throws {
        let metrics = PracticeAreaMetricsCalculator.compute(
            practiceAreas: [] as [PracticeAreaMetricAreaInput],
            ratings: [] as [PracticeAreaMetricRatingInput],
            sessions: [] as [PracticeAreaMetricSessionInput],
            now: try date("2026-06-02T12:00:00Z"),
            calendar: calendar
        )

        XCTAssertTrue(metrics.isEmpty)
    }

    func testSevenDayAndPreviousWindowBoundaries() throws {
        let areaID = UUID()
        let now = try date("2026-06-02T12:00:00Z")

        let metrics = compute(
            areaID: areaID,
            now: now,
            scores: [
                score(6, daysAgo: 14, areaID: areaID),
                score(8, daysAgo: 7, areaID: areaID),
                score(10, daysAgo: 0, areaID: areaID)
            ]
        )

        let metric = try XCTUnwrap(metrics.first)
        XCTAssertEqual(metric.previousSevenDayAverage, 6)
        XCTAssertEqual(metric.sevenDayAverage, 9)
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
        didPractice: Bool = true,
        score: Int?,
        createdAt: Date,
        lastModified: Date
    ) -> PracticeAreaMetricRatingInput {
        PracticeAreaMetricRatingInput(
            sessionID: sessionID,
            practiceAreaID: areaID,
            areaName: areaName,
            didPractice: didPractice,
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
