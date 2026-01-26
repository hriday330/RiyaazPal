//
//  CategorySetupStepView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-25.
//

import Foundation
import SwiftUI

struct CategorySetupStepView: View {

    let title: String
    let subtitle: String
    let category: TagCategoryModel
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // using existing category detail editor
            CategoryDetailView(category: category)

            VStack(spacing: 12) {
                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)

                Button("Skip for now") {
                    onSkip()
                }
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}
