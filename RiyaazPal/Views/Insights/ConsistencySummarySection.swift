//
//  ConsistencySummarySection.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-02-15.
//

import Foundation
import SwiftUI

import SwiftData

struct ConsistencySummarySection: View {
    let consistencyStats: ConsistencyStats
    @EnvironmentObject var router: TabRouter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Consistency")
                        .font(.headline)
                    
                    Text("You practiced \(consistencyStats.practicedDays) out of the last \(consistencyStats.totalDays) days.")
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                    
                    if consistencyStats.streak > 1 {
                        Text("Current streak: \(consistencyStats.streak) days")
                            .font(.caption)
                            .foregroundStyle(Color("SecondaryText"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AccentColor").opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    router.selectedTab = .timeline
                } label: {
                    HStack(spacing: 4) {
                        Text("Practice")
                        Image(systemName: "play.fill")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("AccentColor"))
                    .clipShape(Capsule())
                }
            }
            
            GeometryReader { geo in
                let ratio = Double(consistencyStats.practicedDays) / Double(max(1, consistencyStats.totalDays))
                
                let progressColor: Color = {
                    switch consistencyStats.practicedDays {
                    case 0..<7:
                        return .red
                    case 7..<15:
                        return .orange
                    default:
                        return Color("AccentColor")
                    }
                }()
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(progressColor)
                        .frame(
                            width: geo.size.width * CGFloat(ratio),
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.25), value: ratio)
                        .animation(.easeInOut(duration: 0.25), value: progressColor)
                }
            }
            
            .frame(height: 6)
        }
    }
}
