//
//  InsightsViewModel.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-14.
//

import Foundation
import Combine

final class InsightsViewModel: ObservableObject {
    
    @Published var currentWindow: DateRange = InsightWindowHelper.dateRange()
}
