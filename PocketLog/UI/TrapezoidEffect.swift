//
//  TrapezoidEffect.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 22/11/26.
//

import SwiftUI

struct TrapezoidEffect: GeometryEffect {
    var topWidth: CGFloat
    var bottomWidth: CGFloat

    var topY: CGFloat
    var bottomY: CGFloat
    var centerX: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let w = size.width
        let h = size.height

        guard w > 0, h > 0, bottomWidth > 0 else {
            return ProjectionTransform()
        }

        let a = topWidth / w
        let g = (topWidth / bottomWidth - 1) / h

        let c = centerX - topWidth / 2

        // Corrected horizontal perspective coefficient.
        let b = (
            (centerX - bottomWidth / 2) * (1 + g * h) - c
        ) / h

        let e = topY
        let d = (bottomY * (1 + g * h) - topY) / h

        var t = ProjectionTransform()

        t.m11 = a
        t.m12 = b
        t.m13 = c

        t.m21 = 0
        t.m22 = d
        t.m23 = e

        t.m31 = 0
        t.m32 = g
        t.m33 = 1

        return t
    }
}

extension View {
    func trapezoidEffect(
        topWidth: CGFloat,
        bottomWidth: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        centerX: CGFloat
    ) -> some View {
        self.modifier(
            TrapezoidEffect(
                topWidth: topWidth,
                bottomWidth: bottomWidth,
                topY: topY,
                bottomY: bottomY,
                centerX: centerX
            )
        )
    }
}

struct TrapezoidTestView: View {
    @State var topWidth: CGFloat = 80
    @State var bottomWidth: CGFloat = 80

    @State var topY: CGFloat = 0
    @State var bottomY: CGFloat = 50
    @State var centerX: CGFloat = 40

    var body: some View {
        VStack {
            Rectangle()
                .fill(LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 50)
                .trapezoidEffect(
                    topWidth: topWidth,
                    bottomWidth: bottomWidth,
                    topY: topY,
                    bottomY: bottomY,
                    centerX: centerX
                )

            Text("topWidth: \(topWidth)")
            Slider(value: $topWidth, in: 0...100, step: 1.0)
            Text("bottomWidth: \(bottomWidth)")
            Slider(value: $bottomWidth, in: 0...100, step: 1.0)
            Text("topY: \(topY)")
            Slider(value: $topY, in: 0...100, step: 1.0)
            Text("bottomY: \(bottomY)")
            Slider(value: $bottomY, in: 0...100, step: 1.0)
            Text("centerX: \(centerX)")
            Slider(value: $centerX, in: 0...100, step: 1.0)
        }
    }
}
