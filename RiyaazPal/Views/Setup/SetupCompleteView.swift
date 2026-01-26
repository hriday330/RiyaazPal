//
//  SetupCompleteView.swift
//  RiyaazPal
//
//  Created by Hriday Buddhdev on 2026-01-25.
//

import Foundation
import SwiftUI

struct SetupCompleteView: View {

    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            AnimatedCheckmark()

            Text("You’re all set")
                .font(.title)

            Button("Start Practicing") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.headline)
        }
        .padding()
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.2, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.45, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.3))

        return path
    }
}

struct AnimatedCheckmark: View {

    @State private var drawProgress: CGFloat = 0

    var body: some View {
        CheckmarkShape()
            .trim(from: 0, to: drawProgress)
            .stroke(
                Color.green,
                style: StrokeStyle(
                    lineWidth: 6,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: 64, height: 64)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    drawProgress = 1
                }
            }
    }
}

#Preview("Setup Complete") {
    SetupCompleteView {
    }
}

