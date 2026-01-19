//
//  ActiveSessionBar.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-18.
//

import Foundation
import SwiftUI

struct ActiveSessionBar: View {
    let elapsedTime: TimeInterval
    let action: () -> Void
    
    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack {
            Spacer()

            Button {
                action()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(Color("AccentColor"))

                    Text(formattedElapsedTime)
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryText"))

                    Spacer()

                    Text("Recording")
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("ActiveCardBackground"))
                )
                .shadow(radius: 6)
                .padding(.horizontal)
                .padding(.bottom, 12)
                .ignoresSafeArea()
            }
        }.transition(.move(edge: .bottom).combined(with: .opacity))

    }
}
