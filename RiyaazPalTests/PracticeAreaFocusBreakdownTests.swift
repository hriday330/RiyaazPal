//
//  PracticeAreaFocusBreakdownTests.swift
//  RiyaazPalTests
//
//  Created by Hriday Buddhdev on 2026-06-02.
//

import XCTest

final class PracticeAreaFocusBreakdownTests: XCTestCase {
    func testSlicesIncludeOnlyActiveAreasWithPracticeRatings() {
        let slices = PracticeAreaFocusSlice.slices(
            from: [
                metric(id: "alap", name: "Alap", isActive: true, practiceCount: 4),
                metric(id: "taans", name: "Taans", isActive: true, practiceCount: 2),
                metric(id: "archived", name: "Archived", isActive: false, practiceCount: 10),
                metric(id: "empty", name: "Empty", isActive: true, practiceCount: 0)
            ]
        )

        XCTAssertEqual(slices.map(\.name), ["Alap", "Taans"])
        XCTAssertEqual(slices.map(\.count), [4, 2])
    }

    func testSlicesSortTiesByAreaName() {
        let slices = PracticeAreaFocusSlice.slices(
            from: [
                metric(id: "layakari", name: "Layakari", practiceCount: 3),
                metric(id: "alap", name: "Alap", practiceCount: 3),
                metric(id: "taans", name: "Taans", practiceCount: 5)
            ]
        )

        XCTAssertEqual(slices.map(\.name), ["Taans", "Alap", "Layakari"])
    }

    func testCompactDisplaySlicesKeepsTopFourAndGroupsTheRest() {
        let slices = [
            PracticeAreaFocusSlice(id: "one", name: "One", count: 9),
            PracticeAreaFocusSlice(id: "two", name: "Two", count: 8),
            PracticeAreaFocusSlice(id: "three", name: "Three", count: 7),
            PracticeAreaFocusSlice(id: "four", name: "Four", count: 6),
            PracticeAreaFocusSlice(id: "five", name: "Five", count: 5),
            PracticeAreaFocusSlice(id: "six", name: "Six", count: 4)
        ]

        let compactSlices = PracticeAreaFocusSlice.compactDisplaySlices(from: slices)

        XCTAssertEqual(compactSlices.map(\.name), ["One", "Two", "Three", "Four", "Other"])
        XCTAssertEqual(compactSlices.last?.count, 9)
    }

    func testCompactDisplaySlicesDoesNotGroupFiveOrFewerSlices() {
        let slices = [
            PracticeAreaFocusSlice(id: "one", name: "One", count: 9),
            PracticeAreaFocusSlice(id: "two", name: "Two", count: 8),
            PracticeAreaFocusSlice(id: "three", name: "Three", count: 7),
            PracticeAreaFocusSlice(id: "four", name: "Four", count: 6),
            PracticeAreaFocusSlice(id: "five", name: "Five", count: 5)
        ]

        let compactSlices = PracticeAreaFocusSlice.compactDisplaySlices(from: slices)

        XCTAssertEqual(compactSlices.map(\.name), ["One", "Two", "Three", "Four", "Five"])
    }

    func testWindowedSlicesUseRecentPracticeScoreHistory() {
        let slices = PracticeAreaFocusSlice.slices(
            from: [
                metric(
                    id: "alap",
                    name: "Alap",
                    practiceCount: 2,
                    scoreHistory: [
                        scorePoint(daysAgo: 2),
                        scorePoint(daysAgo: 30)
                    ]
                )
            ],
            inLast: 14
        )

        XCTAssertEqual(slices.map(\.name), ["Alap"])
        XCTAssertEqual(slices.map(\.count), [1])
    }

    func testWindowedSlicesExcludeConcertScoreHistory() {
        let slices = PracticeAreaFocusSlice.slices(
            from: [
                metric(
                    id: "alap",
                    name: "Alap",
                    practiceCount: 2,
                    scoreHistory: [
                        scorePoint(daysAgo: 2),
                        scorePoint(daysAgo: 1, sessionType: .concert)
                    ]
                )
            ],
            inLast: 7
        )

        XCTAssertEqual(slices.map(\.count), [1])
    }

    func testPercentageFormatterShowsLessThanOnePercentForTinyNonZeroSlices() {
        XCTAssertEqual(
            PracticeAreaFocusPercentageFormatter.text(count: 1, totalCount: 1_000),
            "<1%"
        )
        XCTAssertEqual(
            PracticeAreaFocusPercentageFormatter.text(count: 0, totalCount: 1_000),
            "0%"
        )
        XCTAssertEqual(
            PracticeAreaFocusPercentageFormatter.text(count: 6, totalCount: 10),
            "60%"
        )
    }
}

private extension PracticeAreaFocusBreakdownTests {
    func metric(
        id: String,
        name: String,
        isActive: Bool = true,
        practiceCount: Int,
        scoreHistory: [PracticeAreaScorePoint] = []
    ) -> PracticeAreaMetric {
        PracticeAreaMetric(
            id: id,
            areaID: UUID(),
            areaName: name,
            isActive: isActive,
            latestScore: nil,
            sevenDayAverage: nil,
            previousSevenDayAverage: nil,
            thirtyDayAverage: nil,
            trendDirection: .insufficientData,
            ratedSessionCount: practiceCount,
            daysSincePracticed: nil,
            isNeglected: false,
            volatility: nil,
            practice: PracticeAreaContextMetric(
                latestScore: nil,
                averageScore: nil,
                ratedSessionCount: practiceCount,
                volatility: nil
            ),
            concert: PracticeAreaContextMetric(
                latestScore: nil,
                averageScore: nil,
                ratedSessionCount: 0,
                volatility: nil
            ),
            scoreHistory: scoreHistory,
            performanceTransfer: PracticeAreaPerformanceTransfer(
                practiceAverage: nil,
                concertAverage: nil,
                delta: nil,
                status: .insufficientData
            )
        )
    }

    func scorePoint(
        daysAgo: Int,
        sessionType: SessionType = .practice
    ) -> PracticeAreaScorePoint {
        PracticeAreaScorePoint(
            id: UUID(),
            date: Calendar.current.date(
                byAdding: .day,
                value: -daysAgo,
                to: Date()
            ) ?? Date(),
            score: 7,
            sessionType: sessionType
        )
    }
}
